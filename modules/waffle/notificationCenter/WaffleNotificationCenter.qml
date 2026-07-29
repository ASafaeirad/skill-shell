import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.services

Scope {
    id: root

    function toggleOpen() {
        GlobalStates.sidebarRightOpen = !GlobalStates.sidebarRightOpen;
    }

    Connections {
        function onSidebarRightOpenChanged() {
            if (GlobalStates.sidebarRightOpen)
                panelLoader.active = true;

        }

        target: GlobalStates
    }

    Loader {
        id: panelLoader

        active: GlobalStates.sidebarRightOpen

        sourceComponent: PanelWindow {
            id: panelWindow

            exclusiveZone: 0
            WlrLayershell.namespace: "quickshell:wNotificationCenter"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
            color: "transparent"
            implicitWidth: content.implicitWidth
            implicitHeight: content.implicitHeight

            anchors {
                bottom: true
                top: true
                right: true
            }

            HyprlandFocusGrab {
                id: focusGrab

                active: true
                windows: [panelWindow]
                onCleared: content.close()
            }

            Connections {
                function onSidebarRightOpenChanged() {
                    if (!GlobalStates.sidebarRightOpen)
                        content.close();

                }

                target: GlobalStates
            }

            NotificationCenterContent {
                id: content

                anchors.fill: parent
                onClosed: {
                    GlobalStates.sidebarRightOpen = false;
                    panelLoader.active = false;
                }
            }

        }

    }

    IpcHandler {
        function toggle() {
            root.toggleOpen();
        }

        target: "sidebarRight"
    }

    GlobalShortcut {
        name: "sidebarRightToggle"
        description: "Toggles notification center on press"
        onPressed: root.toggleOpen()
    }

}
