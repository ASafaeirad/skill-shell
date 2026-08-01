import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import qs
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.services

Scope {
    id: root

    function toggleClipboard() {
        if (SearchPrefixes.detect(LauncherSearch.query) === SearchPrefixes.PrefixKind.Clipboard || !GlobalStates.searchOpen)
            GlobalStates.searchOpen = !GlobalStates.searchOpen;

        LauncherSearch.query = SearchPrefixes.ensurePrefix(LauncherSearch.query, SearchPrefixes.PrefixKind.Clipboard);
    }

    function toggleEmojis() {
        if (SearchPrefixes.detect(LauncherSearch.query) === SearchPrefixes.PrefixKind.Emojis || !GlobalStates.searchOpen)
            GlobalStates.searchOpen = !GlobalStates.searchOpen;

        LauncherSearch.query = SearchPrefixes.ensurePrefix(LauncherSearch.query, SearchPrefixes.PrefixKind.Emojis);
    }

    Connections {
        function onSearchOpenChanged() {
            if (GlobalStates.searchOpen) {
                LauncherSearch.query = "";
                panelLoader.active = true;
            }
        }

        target: GlobalStates
    }

    Loader {
        id: panelLoader

        active: GlobalStates.searchOpen

        sourceComponent: PanelWindow {
            id: panelWindow

            exclusiveZone: 0
            WlrLayershell.namespace: "quickshell:wStartMenu"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
            color: "transparent"
            implicitWidth: content.implicitWidth
            implicitHeight: content.implicitHeight

            anchors {
                bottom: Config.options.waffles.bar.bottom
                top: !Config.options.waffles.bar.bottom
                left: Config.options.waffles.bar.leftAlignApps
            }

            HyprlandFocusGrab {
                id: focusGrab

                active: true
                windows: [panelWindow]
                onCleared: content.close()
            }

            Connections {
                function onSearchOpenChanged() {
                    if (!GlobalStates.searchOpen)
                        content.close();

                }

                target: GlobalStates
            }

            StartMenuContent {
                id: content

                anchors.fill: parent
                focus: true
                onClosed: {
                    GlobalStates.searchOpen = false;
                    panelLoader.active = false;
                    LauncherSearch.query = "";
                }
            }

        }

    }

    IpcHandler {
        function toggle() {
            GlobalStates.searchOpen = !GlobalStates.searchOpen;
        }

        function close() {
            GlobalStates.searchOpen = false;
        }

        function open() {
            GlobalStates.searchOpen = true;
        }

        function toggleReleaseInterrupt() {
            GlobalStates.superReleaseMightTrigger = false;
        }

        target: "search"
    }

    GlobalShortcut {
        name: "searchToggle"
        description: "Toggles search on press"
        onPressed: {
            GlobalStates.searchOpen = !GlobalStates.searchOpen;
        }
    }

    GlobalShortcut {
        name: "searchToggleRelease"
        description: "Toggles search on release"
        onPressed: {
            GlobalStates.superReleaseMightTrigger = true;
        }
        onReleased: {
            if (!GlobalStates.superReleaseMightTrigger) {
                GlobalStates.superReleaseMightTrigger = true;
                return ;
            }
            GlobalStates.searchOpen = !GlobalStates.searchOpen;
        }
    }

    GlobalShortcut {
        name: "searchToggleReleaseInterrupt"
        description: "Interrupts possibility of search being toggled on release. " + "This is necessary because GlobalShortcut.onReleased in quickshell triggers whether or not you press something else while holding the key. " + "To make sure this works consistently, use binditn = MODKEYS, catchall in an automatically triggered submap that includes everything."
        onPressed: {
            GlobalStates.superReleaseMightTrigger = false;
        }
    }

    GlobalShortcut {
        name: "overviewClipboardToggle"
        description: "Toggle clipboard query on overview widget"
        onPressed: {
            root.toggleClipboard();
        }
    }

    GlobalShortcut {
        name: "overviewEmojiToggle"
        description: "Toggle emoji query on overview widget"
        onPressed: {
            root.toggleEmojis();
        }
    }

}
