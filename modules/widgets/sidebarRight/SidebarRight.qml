import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import Quickshell.Io
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

Panel {
    id: root
    name: "sidebarRight"
    description: "Toggles right sidebar on press"
    hasOpenCloseShortcuts: true
    property int sidebarWidth: Appearance.sizes.sidebarWidth

    onOpenedChanged: {
        if (root.opened) {
            Notifications.timeoutAll();
            Notifications.markAllRead();
        }
    }

    PanelWindow {
        id: panelWindow
        visible: root.opened

        function hide() {
            root.close();
        }

        exclusiveZone: 0
        implicitWidth: sidebarWidth
        WlrLayershell.namespace: "quickshell:sidebarRight"
        WlrLayershell.keyboardFocus: root.opened ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        color: "transparent"

        anchors {
            top: true
            right: true
            bottom: true
        }

        onVisibleChanged: {
            if (visible) {
                GlobalFocusGrab.addDismissable(panelWindow);
            } else {
                GlobalFocusGrab.removeDismissable(panelWindow);
            }
        }
        Connections {
            target: GlobalFocusGrab
            function onDismissed() {
                root.close();
            }
        }

        Loader {
            id: sidebarContentLoader
            active: root.opened || Config?.options.sidebar.keepRightSidebarLoaded
            anchors {
                fill: parent
                margins: Appearance.sizes.hyprlandGapsOut
                leftMargin: Appearance.sizes.elevationMargin
            }
            width: sidebarWidth - Appearance.sizes.hyprlandGapsOut - Appearance.sizes.elevationMargin
            height: parent.height - Appearance.sizes.hyprlandGapsOut * 2

            focus: root.opened
            Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape) {
                    root.close();
                }
            }

            sourceComponent: SidebarRightContent {}
        }
    }
}
