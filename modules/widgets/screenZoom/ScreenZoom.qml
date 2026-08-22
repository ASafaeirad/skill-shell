pragma ComponentBehavior: Bound

import qs
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Scope {
    id: root

    readonly property var currentScreen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? null

    function open() {
        GlobalStates.screenZoomOpen = true;
    }

    function close() {
        GlobalStates.screenZoomOpen = false;
    }

    function toggle() {
        GlobalStates.screenZoomOpen = !GlobalStates.screenZoomOpen;
    }

    Loader {
        id: zoomLoader
        property var lockedScreen
        active: false

        Connections {
            target: GlobalStates
            function onScreenZoomOpenChanged() {
                if (!GlobalStates.screenZoomOpen) {
                    zoomLoader.active = false;
                } else {
                    zoomLoader.lockedScreen = root.currentScreen;
                    zoomLoader.active = true;
                }
            }
        }

        sourceComponent: ScreenZoomPanel {
            screen: zoomLoader.lockedScreen
            onDismiss: root.close()
        }
    }

    IpcHandler {
        target: "screenZoom"

        function toggle() {
            root.toggle();
        }
        function open() {
            root.open();
        }
        function close() {
            root.close();
        }
    }

    GlobalShortcut {
        name: "screenZoomToggle"
        description: "Freeze the screen and zoom into the pointer"
        onPressed: root.toggle()
    }
}
