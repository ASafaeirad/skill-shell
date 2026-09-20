pragma ComponentBehavior: Bound

import qs
import qs.modules.common.widgets
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Panel {
    id: root
    name: "screenZoom"
    description: "Freeze the screen and zoom into the pointer"

    readonly property var currentScreen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? null

    Loader {
        id: zoomLoader
        property var lockedScreen
        active: false

        Connections {
            target: root
            function onOpenedChanged() {
                if (!root.opened) {
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
}
