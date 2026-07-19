import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: root
    property var focusedScreen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name)

    // Modifier keys currently held down, e.g. { "KEY_LEFTCTRL": true }
    property var heldModifiers: ({})

    readonly property var modifierNames: ({
        "KEY_LEFTCTRL": "Ctrl", "KEY_RIGHTCTRL": "Ctrl",
        "KEY_LEFTSHIFT": "Shift", "KEY_RIGHTSHIFT": "Shift",
        "KEY_LEFTALT": "Alt", "KEY_RIGHTALT": "AltGr",
        "KEY_LEFTMETA": "Super", "KEY_RIGHTMETA": "Super"
    })

    readonly property var specialNames: ({
        "ESC": "Esc", "ENTER": "Enter", "SPACE": "Space", "TAB": "Tab",
        "BACKSPACE": "⌫", "CAPSLOCK": "Caps", "DELETE": "Del", "INSERT": "Ins",
        "UP": "↑", "DOWN": "↓", "LEFT": "←", "RIGHT": "→",
        "PAGEUP": "PgUp", "PAGEDOWN": "PgDn", "HOME": "Home", "END": "End",
        "MINUS": "-", "EQUAL": "=", "LEFTBRACE": "[", "RIGHTBRACE": "]",
        "SEMICOLON": ";", "APOSTROPHE": "'", "GRAVE": "`", "BACKSLASH": "\\",
        "COMMA": ",", "DOT": ".", "SLASH": "/", "SYSRQ": "PrtSc",
        "KPPLUS": "Num +", "KPMINUS": "Num -", "KPASTERISK": "Num *",
        "KPSLASH": "Num /", "KPDOT": "Num .", "KPENTER": "Num Enter",
        "NUMLOCK": "NumLk", "SCROLLLOCK": "ScrLk", "MENU": "Menu",
        "PAUSE": "Pause", "PRINT": "PrtSc"
    })

    function prettyKeyName(rawName) {
        let name = rawName.replace(/^KEY_/, "");
        if (specialNames[name] !== undefined)
            return specialNames[name];
        if (name.startsWith("KP") && name.length > 2)
            return "Num " + name.slice(2);
        if (name.length > 1)
            return name.charAt(0) + name.slice(1).toLowerCase();
        return name;
    }

    function activeModifierPrefix() {
        const order = ["Super", "Ctrl", "Alt", "AltGr", "Shift"];
        const active = [];
        for (const key in heldModifiers) {
            const pretty = modifierNames[key];
            if (heldModifiers[key] && !active.includes(pretty))
                active.push(pretty);
        }
        active.sort((a, b) => order.indexOf(a) - order.indexOf(b));
        return active;
    }

    function pushChip(label) {
        if (keyChips.count > 0) {
            const last = keyChips.get(keyChips.count - 1);
            if (last.label === label) {
                keyChips.setProperty(keyChips.count - 1, "count", last.count + 1);
                chipTimeout.restart();
                return;
            }
        }
        keyChips.append({ "label": label, "count": 1 });
        while (keyChips.count > Config.options.keyDisplay.maxKeys)
            keyChips.remove(0);
        chipTimeout.restart();
    }

    function handleEvent(line) {
        let event;
        try {
            event = JSON.parse(line);
        } catch (e) {
            return; // Startup noise (permission warnings etc.)
        }
        if (event.event_name !== "KEYBOARD_KEY")
            return; // Ignore pointer button events

        const isModifier = modifierNames[event.key_name] !== undefined;
        if (event.state_name === "RELEASED") {
            if (isModifier) {
                const mods = heldModifiers;
                delete mods[event.key_name];
                heldModifiers = mods;
            }
            return;
        }

        if (isModifier) {
            const mods = heldModifiers;
            mods[event.key_name] = true;
            heldModifiers = mods;
            return; // Shown as prefix of the next real key
        }

        const parts = activeModifierPrefix();
        parts.push(prettyKeyName(event.key_name));
        pushChip(parts.join(" + "));
    }

    ListModel {
        id: keyChips
    }

    Timer {
        id: chipTimeout
        interval: Config.options.keyDisplay.timeout
        repeat: false
        onTriggered: keyChips.clear()
    }

    Process {
        id: keyReader
        // Root is needed to read /dev/input; the shipped polkit rule lets
        // wheel members run this without a password prompt
        command: ["pkexec", "/usr/bin/showmethekey-cli"]
        stdinEnabled: true
        stdout: SplitParser {
            onRead: line => root.handleEvent(line)
        }
        onRunningChanged: {
            if (!running) {
                keyChips.clear();
                root.heldModifiers = ({});
            }
        }

        // The backend runs as root, so we can't signal it — it must be told
        // to exit via its stdin "stop" command (same thing the smtk GUI does)
        function requestStop() {
            if (running)
                write("stop\n");
        }
    }

    Connections {
        target: GlobalStates
        function onKeyDisplayOpenChanged() {
            if (GlobalStates.keyDisplayOpen)
                keyReader.running = true;
            else
                keyReader.requestStop();
        }
    }

    Component.onDestruction: keyReader.requestStop()

    Loader {
        id: panelLoader
        active: GlobalStates.keyDisplayOpen && keyChips.count > 0

        sourceComponent: PanelWindow {
            id: panelRoot
            color: "transparent"
            screen: root.focusedScreen

            WlrLayershell.namespace: "quickshell:keyDisplay"
            WlrLayershell.layer: WlrLayer.Overlay
            exclusionMode: ExclusionMode.Ignore
            exclusiveZone: 0
            anchors.bottom: true
            margins.bottom: Appearance.sizes.barHeight * 2
            // Empty region: clicks pass through
            mask: Region {}

            implicitWidth: chipRow.implicitWidth + Appearance.sizes.elevationMargin * 2
            implicitHeight: chipRow.implicitHeight + Appearance.sizes.elevationMargin * 2
            visible: panelLoader.active

            RowLayout {
                id: chipRow
                anchors.centerIn: parent
                spacing: 8

                Repeater {
                    model: keyChips

                    delegate: Item {
                        id: chip
                        required property string label
                        required property int count

                        implicitWidth: chipBackground.implicitWidth
                        implicitHeight: chipBackground.implicitHeight

                        scale: 0.7
                        opacity: 0
                        Component.onCompleted: {
                            scale = 1;
                            opacity = 1;
                        }
                        Behavior on scale {
                            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                        }
                        Behavior on opacity {
                            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                        }

                        StyledRectangularShadow {
                            target: chipBackground
                        }
                        Rectangle {
                            id: chipBackground
                            anchors.centerIn: parent
                            property real padding: 12
                            implicitWidth: chipText.implicitWidth + padding * 2
                            implicitHeight: chipText.implicitHeight + padding
                            radius: Appearance.rounding.normal
                            color: Appearance.colors.colLayer0

                            Behavior on implicitWidth {
                                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                            }

                            StyledText {
                                id: chipText
                                anchors.centerIn: parent
                                font.pixelSize: Appearance.font.pixelSize.huge
                                color: Appearance.colors.colOnLayer0
                                text: chip.count > 1 ? `${chip.label} ×${chip.count}` : chip.label
                            }
                        }
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "keyDisplay"

        function open(): void {
            GlobalStates.keyDisplayOpen = true;
        }

        function close(): void {
            GlobalStates.keyDisplayOpen = false;
        }

        function toggle(): void {
            GlobalStates.keyDisplayOpen = !GlobalStates.keyDisplayOpen;
        }
    }

    GlobalShortcut {
        name: "keyDisplayToggle"
        description: "Toggles on-screen key press display"

        onPressed: {
            GlobalStates.keyDisplayOpen = !GlobalStates.keyDisplayOpen;
        }
    }
}
