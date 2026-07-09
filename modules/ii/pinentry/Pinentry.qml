pragma ComponentBehavior: Bound
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Scope {
    id: root

    property string description: ""
    property string promptLabel: Translation.tr("Passphrase")
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
        root.promptLabel = b64decode(labelB64) || Translation.tr("Passphrase");
        root.errorText = b64decode(errB64);
        root.fifoPath = fifo;
        root.visibleInput = (visible === "1");
        GlobalStates.pinentryOpen = true;
    }

    // Send the answer back to the script over the FIFO. The secret travels via
    // the process's stdin only — never argv, never this shell's IPC stdout.
    function respond(prefix, text) {
        if (root.fifoPath.length === 0) return;
        writer.payload = prefix + (text ?? "") + "\n";
        writer.command = ["sh", "-c", 'cat > "$1"', "sh", root.fifoPath];
        writer.stdinEnabled = true;
        writer.running = true;
        root.fifoPath = "";
        GlobalStates.pinentryOpen = false;
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

    Loader {
        active: GlobalStates.pinentryOpen
        sourceComponent: Variants {
            model: Quickshell.screens
            delegate: PanelWindow {
                id: panelWindow
                required property var modelData
                screen: modelData

                anchors {
                    top: true
                    left: true
                    right: true
                    bottom: true
                }

                color: "transparent"
                WlrLayershell.namespace: "quickshell:pinentry"
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
                WlrLayershell.layer: WlrLayer.Overlay
                exclusionMode: ExclusionMode.Ignore

                Item {
                    anchors.fill: parent
                    focus: true
                    Component.onCompleted: inputField.forceActiveFocus()

                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Escape) root.cancel();
                    }

                    WindowDialog {
                        anchors.fill: parent
                        backgroundWidth: 450
                        show: false
                        Component.onCompleted: show = true
                        onDismiss: root.cancel()

                        MaterialSymbol {
                            Layout.alignment: Qt.AlignHCenter
                            iconSize: 26
                            text: "password"
                            color: Appearance.colors.colSecondary
                        }

                        WindowDialogTitle {
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                            text: Translation.tr("Passphrase required")
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
                                if (event.key === Qt.Key_Escape) root.cancel();
                            }
                        }

                        WindowDialogButtonRow {
                            Layout.bottomMargin: 10
                            Item { Layout.fillWidth: true }
                            DialogButton {
                                buttonText: Translation.tr("Cancel")
                                onClicked: root.cancel()
                            }
                            DialogButton {
                                buttonText: Translation.tr("OK")
                                onClicked: root.submit(inputField.text)
                            }
                        }
                    }
                }
            }
        }
    }
}
