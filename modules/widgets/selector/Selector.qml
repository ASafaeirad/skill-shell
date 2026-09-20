import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

Panel {
    id: root
    name: "selector"
    description: "Toggle the generic selector"
    manageIpc: false

    // The list of choices to show. Either plain strings, or objects
    // like { name: "Foo", icon: "settings" }.
    property var items: [
        "Alpha", "Bravo", "Charlie", "Delta", "Echo",
        "Foxtrot", "Golf", "Hotel", "India", "Juliet"
    ]
    property string prompt: "Select an item"

    // dmenu-style free-form input: accept text the user typed even when it
    // isn't one of `items`. `items` may be empty for a pure text prompt.
    property bool allowCustom: false

    // Emitted when the user confirms a choice. `item` is the original entry
    // from `items` (string or object); `index` is its position.
    signal selected(var item, int index)

    // When set (e.g. by the run() IPC below), the chosen line is written here
    // so a shell script can read it back. Cleared after each use.
    property string resultPath: ""

    // The qs ipc CLI mangles commas, so items arrive '|'-separated.
    function parseItems(pipeSeparated) {
        return String(pipeSeparated ?? "").split("|").map(s => s.trim()).filter(s => s.length > 0);
    }

    function textOf(item) {
        return (typeof item === "object" && item !== null) ? (item.value ?? item.name ?? "") : String(item);
    }

    // Called on confirm (text = the chosen line) and on cancel (text = "").
    // Always writes to resultPath if set, so a blocked reader unblocks either way.
    function finish(text): void {
        root.opened = false;
        if (root.resultPath.length > 0) {
            dialog.writeResult(root.resultPath, text);
            root.resultPath = "";
        }
        dialog.close();
    }

    function open(): void {
        root.opened = true;
        dialog.open();
    }
    function close(): void {
        // Treat an external close as a cancel so readers don't hang.
        root.finish("");
    }
    function toggle(): void {
        if (dialog.opened)
            root.finish("");
        else
            root.open();
    }

    OverlayDialog {
        id: dialog

        layerNamespace: "quickshell:selector"
        keyboardFocus: WlrKeyboardFocus.OnDemand
        onDismissed: root.finish("")

        SelectorContent {
            items: root.items
            prompt: root.prompt
            allowCustom: root.allowCustom
            onSelected: (item, index) => {
                root.selected(item, index);
                root.finish(root.textOf(item));
            }
            onSubmitted: text => root.finish(text)
            onCancelled: root.finish("")
        }
    }

    IpcHandler {
        target: "selector"

        function toggle(): void {
            root.toggle();
        }
        function open(): void {
            root.open();
        }
        function close(): void {
            root.close();
        }
        // Set the input label / placeholder shown in the search field. Persists
        // until changed; call before setItems/run/open. e.g.
        //   qs -c skill ipc call selector setPrompt 'Pick an action'
        function setPrompt(label: string): void {
            root.prompt = label;
        }
        // Pass the choices directly as an argument, pipe-separated. e.g.
        //   qs -c skill ipc call selector setItems 'Reboot|Shutdown|Suspend|Lock|Log out'
        // The qs ipc CLI mangles commas, so '|' (not ',') is the separator.
        function setItems(pipeSeparated: string): void {
            root.allowCustom = false;
            root.items = root.parseItems(pipeSeparated);
            root.open();
        }

        // dmenu-style: read choices from a file, one item per line. e.g.
        //   printf 'Reboot\nShutdown\nSuspend\n' > /tmp/menu
        //   qs -c skill ipc call selector fromFile /tmp/menu
        function fromFile(path: string): void {
            root.allowCustom = false;
            itemsFile.path = path;
            itemsFile.reload();
        }

        // Full round-trip: show pipe-separated items and write the chosen line
        // (or an empty line if cancelled) to fifoPath. Pair with a reader:
        //   fifo=$(mktemp -u); mkfifo "$fifo"
        //   qs -c skill ipc call selector run 'A|B|C' "$fifo"
        //   choice=$(cat "$fifo"); rm "$fifo"
        function run(pipeSeparated: string, fifoPath: string): void {
            root.allowCustom = false;
            root.items = root.parseItems(pipeSeparated);
            root.resultPath = fifoPath;
            root.open();
        }

        // Like run(), but free-form: whatever the user typed is written to
        // fifoPath when it matches no entry (Shift+Enter forces the typed text).
        // Pass an empty item list for a plain text prompt. e.g.
        //   qs -c skill ipc call selector runFreeform '' "$fifo"
        function runFreeform(pipeSeparated: string, fifoPath: string): void {
            root.allowCustom = true;
            root.items = root.parseItems(pipeSeparated);
            root.resultPath = fifoPath;
            root.open();
        }
    }

    FileView {
        id: itemsFile
        onLoaded: {
            const lines = text().split("\n").map(l => l.trim()).filter(l => l.length > 0);
            root.items = lines;
            root.open();
        }
        onLoadFailed: error => {
            console.warn("[Selector] fromFile() could not read", path, error);
        }
    }
}
