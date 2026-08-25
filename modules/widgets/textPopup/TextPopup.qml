import qs
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.services
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

/**
 * A read-only text dialog, the shell-native replacement for `zenity --text-info`.
 * Driven from scripts through the "popup" IPC target; see ~/.local/bin/popup.
 */
Scope {
    id: root

    property string title: ""
    property string body: ""

    // When set, an empty line is written here once the popup closes, so a
    // script blocked on `cat "$fifo"` unblocks (and can clean up its temp file).
    property string donePath: ""

    // True while the dialog's exit animation is playing; keeps the panel
    // loaded until the animation finishes.
    property bool closing: false

    function open(): void {
        GlobalStates.textPopupOpen = true;
    }

    function close(): void {
        if (root.donePath.length > 0) {
            doneWriter.write(root.donePath);
            root.donePath = "";
        }
        // Flip the public state now, but keep the window alive to play the
        // slide-down; the content signals closeFinished when it's done.
        const c = popupLoader.item?.popupContent ?? null;
        if (c && GlobalStates.textPopupOpen) {
            root.closing = true;
            c.animateOut();
        }
        GlobalStates.textPopupOpen = false;
    }

    function show(title: string, body: string): void {
        root.title = title;
        root.body = body;
        root.open();
    }

    Process {
        id: doneWriter
        property string outPath: ""
        command: ["bash", "-c", `printf '\n' > '${StringUtils.shellSingleQuoteEscape(doneWriter.outPath)}'`]
        function write(path) {
            doneWriter.outPath = path;
            doneWriter.running = true;
        }
    }

    // Body text arrives via a file: IPC arguments can't carry newlines, and the
    // qs ipc CLI mangles commas.
    FileView {
        id: bodyFile
        onLoaded: {
            root.body = text();
            root.open();
        }
        onLoadFailed: error => {
            console.warn("[TextPopup] could not read", path, error);
            root.body = `Could not read ${path}`;
            root.open();
        }
    }

    Loader {
        id: popupLoader
        active: GlobalStates.textPopupOpen || root.closing

        sourceComponent: OverlayDialogWindow {
            id: panelWindow

            readonly property alias popupContent: content

            layerNamespace: "quickshell:textPopup"
            keyboardFocus: WlrKeyboardFocus.Exclusive // Modal like Pinentry: Esc/Enter dismiss without clicking first
            // Dim everything behind the dialog and fade the scrim with it.
            scrimOpacity: content.opacity
            onDismissed: root.close()

            TextPopupContent {
                id: content

                anchors.centerIn: parent
                focus: true
                title: root.title
                body: root.body
                onDismissed: root.close()
                onCloseFinished: root.closing = false
            }
        }
    }

    // If reopened mid-close, cancel the exit and slide back in.
    Connections {
        target: GlobalStates
        function onTextPopupOpenChanged() {
            if (GlobalStates.textPopupOpen && root.closing) {
                root.closing = false;
                popupLoader.item?.popupContent?.animateIn();
            }
        }
    }

    IpcHandler {
        target: "popup"

        // Short, single-line messages only: the qs ipc CLI mangles commas and
        // can't carry newlines. e.g.
        //   qs -c skill ipc call popup show 'Title' 'Hello there'
        function show(title: string, body: string): void {
            root.show(title, body);
        }

        // The general form: body text is read from a file. When donePath is a
        // non-empty path (typically a fifo), a line is written to it once the
        // popup closes. Pass '' to not signal anything. e.g.
        //   qs -c skill ipc call popup showFile 'English' /tmp/ocr.txt ''
        function showFile(title: string, path: string, donePath: string): void {
            root.title = title;
            root.donePath = donePath;
            bodyFile.path = "";
            bodyFile.path = path;
            bodyFile.reload();
        }

        function close(): void {
            root.close();
        }
    }
}
