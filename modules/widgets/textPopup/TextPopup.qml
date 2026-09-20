import qs.modules.common.widgets
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

/**
 * A read-only text dialog, the shell-native replacement for `zenity --text-info`.
 * Driven from scripts through the "popup" IPC target; see ~/.local/bin/popup.
 */
Panel {
    id: root
    name: "popup"
    manageIpc: false
    hasToggleShortcut: false

    property string title: ""
    property string body: ""

    // When set, an empty line is written here once the popup closes, so a
    // script blocked on `cat "$fifo"` unblocks (and can clean up its temp file).
    property string donePath: ""

    function open(): void {
        root.opened = true;
        dialog.open();
    }

    function close(): void {
        root.opened = false;
        if (root.donePath.length > 0) {
            dialog.writeResult(root.donePath, "");
            root.donePath = "";
        }
        dialog.close();
    }

    function show(title: string, body: string): void {
        root.title = title;
        root.body = body;
        root.open();
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

    OverlayDialog {
        id: dialog

        layerNamespace: "quickshell:textPopup"
        keyboardFocus: WlrKeyboardFocus.Exclusive // Modal like Pinentry: Esc/Enter dismiss without clicking first
        onDismissed: root.close()

        TextPopupContent {
            focus: true
            title: root.title
            body: root.body
            onDismissed: root.close()
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
