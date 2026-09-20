pragma ComponentBehavior: Bound
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Panel {
    id: root
    name: "pinentry"
    manageIpc: false
    hasToggleShortcut: false

    property string description: ""
    property string promptLabel: "Passphrase"
    property string errorText: ""
    property string fifoPath: ""
    property bool visibleInput: false

    // Decode base64 (from the pinentry script) into a proper UTF-8 string.
    function b64decode(s) {
        if (!s || s.length === 0) return "";
        const raw = Qt.atob(s);
        try {
            return decodeURIComponent(escape(raw)); // reinterpret Latin-1 bytes as UTF-8
        } catch (e) {
            return raw;
        }
    }

    function open(descB64, labelB64, errB64, fifo, visible) {
        root.description = b64decode(descB64);
        root.promptLabel = b64decode(labelB64) || "Passphrase";
        root.errorText = b64decode(errB64);
        root.fifoPath = fifo;
        root.visibleInput = (visible === "1");
        root.opened = true;
        dialog.open();
    }

    // Send the answer back to the script over the FIFO. The secret travels via
    // the process's stdin only — never argv, never this shell's IPC stdout.
    function respond(prefix, text) {
        if (root.fifoPath.length === 0) return;
        // A caller can disappear while the writer is opening its FIFO. Stop
        // that abandoned writer before reusing this Process for a new reply.
        writer.running = false;
        writer.payload = prefix + (text ?? "") + "\n";
        writer.command = ["timeout", "5", "sh", "-c", 'cat > "$1"', "sh", root.fifoPath];
        writer.stdinEnabled = true;
        writer.running = true;
        root.fifoPath = "";
        root.opened = false;
        dialog.close();
    }

    function submit(pass) { root.respond("D:", pass); }
    function cancel() { root.respond("C:", ""); }

    Process {
        id: writer
        property string payload: ""
        onRunningChanged: {
            if (running) {
                writer.write(payload);
                payload = "";
                stdinEnabled = false; // close stdin so `cat` finishes
            }
        }
    }

    IpcHandler {
        target: "pinentry"

        function prompt(desc: string, label: string, err: string, fifo: string, visible: string): void {
            root.open(desc, label, err, fifo, visible);
        }

        function ping(): string {
            return "ok";
        }
    }

    OverlayDialog {
        id: dialog

        layerNamespace: "quickshell:pinentry"
        keyboardFocus: WlrKeyboardFocus.Exclusive
        // The prompt is modal: only answering it closes the dialog, and it
        // shows up wherever the user is looking.
        dismissOnFocusGrab: false
        allScreens: true
        onDismissed: root.cancel()

        OverlayDialogCard {
            id: dialogCard

            focus: true
            implicitWidth: 450
            implicitHeight: 2 * Appearance.sizes.elevationMargin + 2 * padding + contentColumn.implicitHeight

            Component.onCompleted: {
                inputField.forceActiveFocus();
                animateIn();
            }
            // Reopening while the exit animation is still playing reuses
            // this instance, so drop whatever was typed before.
            onAboutToAnimateIn: {
                inputField.text = "";
                inputField.forceActiveFocus();
            }

            Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape) {
                    root.cancel();
                    event.accepted = true;
                } else {
                    event.accepted = false;
                }
            }

            ColumnLayout {
                id: contentColumn

                spacing: 16
                anchors {
                    fill: parent
                    margins: dialogCard.padding
                }

                MaterialSymbol {
                    Layout.alignment: Qt.AlignHCenter
                    iconSize: 26
                    text: "password"
                    color: Appearance.colors.colSecondary
                }

                WindowDialogTitle {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: "Passphrase required"
                }

                WindowDialogParagraph {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignLeft
                    visible: root.description.length > 0
                    text: root.description
                }

                WindowDialogParagraph {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignLeft
                    visible: root.errorText.length > 0
                    color: Appearance.m3colors.m3error
                    text: root.errorText
                }

                MaterialTextField {
                    id: inputField

                    Layout.fillWidth: true
                    focus: true
                    placeholderText: root.promptLabel
                    echoMode: root.visibleInput ? TextInput.Normal : TextInput.Password
                    onAccepted: root.submit(inputField.text)

                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Escape) {
                            root.cancel();
                            event.accepted = true;
                        }
                    }
                }

                WindowDialogButtonRow {
                    Layout.bottomMargin: 10

                    Item {
                        Layout.fillWidth: true
                    }

                    DialogButton {
                        buttonText: "Cancel"
                        onClicked: root.cancel()
                    }

                    DialogButton {
                        buttonText: "OK"
                        onClicked: root.submit(inputField.text)
                    }
                }
            }
        }
    }
}
