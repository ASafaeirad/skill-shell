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

Scope {
    id: root

    // The list of choices to show. Either plain strings, or objects
    // like { name: "Foo", icon: "settings" }.
    property var items: [
        "Alpha", "Bravo", "Charlie", "Delta", "Echo",
        "Foxtrot", "Golf", "Hotel", "India", "Juliet"
    ]
    property string prompt: Translation.tr("Select an item")

    // Emitted when the user confirms a choice. `item` is the original entry
    // from `items` (string or object); `index` is its position.
    signal selected(var item, int index)

    // When set (e.g. by the run() IPC below), the chosen line is written here
    // so a shell script can read it back. Cleared after each use.
    property string resultPath: ""

    function textOf(item) {
        return (typeof item === "object" && item !== null) ? (item.value ?? item.name ?? "") : String(item);
    }

    // True while the slide-down exit animation is playing; keeps the panel
    // loaded until the animation finishes.
    property bool closing: false

    // Called on confirm (text = the chosen line) and on cancel (text = "").
    // Always writes to resultPath if set, so a blocked reader unblocks either way.
    function finish(text): void {
        if (root.resultPath.length > 0) {
            resultWriter.write(root.resultPath, text);
            root.resultPath = "";
        }
        // Flip the public state now, but keep the window alive to play the
        // slide-down; the content signals closeFinished when it's done.
        const c = selectorLoader.item?.selectorContent ?? null;
        if (c && GlobalStates.selectorOpen) {
            root.closing = true;
            c.animateOut();
        }
        GlobalStates.selectorOpen = false;
    }

    function open(): void {
        GlobalStates.selectorOpen = true;
    }
    function close(): void {
        // Treat an external close as a cancel so readers don't hang.
        root.finish("");
    }
    function toggle(): void {
        if (GlobalStates.selectorOpen)
            root.finish("");
        else
            root.open();
    }

    Process {
        id: resultWriter
        property string outPath: ""
        property string outText: ""
        command: ["bash", "-c", `printf '%s\n' '${StringUtils.shellSingleQuoteEscape(resultWriter.outText)}' > '${StringUtils.shellSingleQuoteEscape(resultWriter.outPath)}'`]
        function write(path, text) {
            resultWriter.outText = text;
            resultWriter.outPath = path;
            resultWriter.running = true;
        }
    }

    Loader {
        id: selectorLoader
        active: GlobalStates.selectorOpen || root.closing

        sourceComponent: PanelWindow {
            id: panelWindow
            readonly property alias selectorContent: content
            readonly property HyprlandMonitor monitor: Hyprland.monitorFor(panelWindow.screen)
            property bool monitorIsFocused: (Hyprland.focusedMonitor?.id == monitor?.id)

            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "quickshell:selector"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
            color: "transparent"

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            // Full-window scrim like Pinentry: dim everything behind the dialog
            // and capture clicks outside it to dismiss.
            Rectangle {
                anchors.fill: parent
                color: Appearance.colors.colScrim
                opacity: content.opacity
                MouseArea {
                    anchors.fill: parent
                    onClicked: root.finish("")
                }
            }

            Component.onCompleted: GlobalFocusGrab.addDismissable(panelWindow)
            Component.onDestruction: GlobalFocusGrab.removeDismissable(panelWindow)
            Connections {
                target: GlobalFocusGrab
                function onDismissed() {
                    root.finish("");
                }
            }

            SelectorContent {
                id: content
                anchors.centerIn: parent
                items: root.items
                prompt: root.prompt
                onSelected: (item, index) => {
                    root.selected(item, index);
                    root.finish(root.textOf(item));
                }
                onCancelled: root.finish("")
                onCloseFinished: root.closing = false
            }
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
            const list = pipeSeparated.split("|").map(s => s.trim()).filter(s => s.length > 0);
            root.items = list;
            root.open();
        }

        // dmenu-style: read choices from a file, one item per line. e.g.
        //   printf 'Reboot\nShutdown\nSuspend\n' > /tmp/menu
        //   qs -c skill ipc call selector fromFile /tmp/menu
        function fromFile(path: string): void {
            itemsFile.path = path;
            itemsFile.reload();
        }

        // Full round-trip: show pipe-separated items and write the chosen line
        // (or an empty line if cancelled) to fifoPath. Pair with a reader:
        //   fifo=$(mktemp -u); mkfifo "$fifo"
        //   qs -c skill ipc call selector run 'A|B|C' "$fifo"
        //   choice=$(cat "$fifo"); rm "$fifo"
        function run(pipeSeparated: string, fifoPath: string): void {
            const list = pipeSeparated.split("|").map(s => s.trim()).filter(s => s.length > 0);
            root.items = list;
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

    // If reopened mid-close, cancel the exit and slide back in.
    Connections {
        target: GlobalStates
        function onSelectorOpenChanged() {
            if (GlobalStates.selectorOpen && root.closing) {
                root.closing = false;
                selectorLoader.item?.selectorContent?.animateIn();
            }
        }
    }

    GlobalShortcut {
        name: "selectorToggle"
        description: "Toggle the generic selector"
        onPressed: root.toggle()
    }
}
