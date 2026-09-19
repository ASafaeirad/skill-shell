import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

import Quickshell.Widgets

Item {
    id: root
    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(root.QsWindow.window?.screen)
    readonly property Toplevel activeWindow: ToplevelManager.activeToplevel

    property string activeWindowAddress: `0x${activeWindow?.HyprlandToplevel?.address}`
    property bool focusingThisMonitor: HyprlandData.activeWorkspace?.monitor == monitor?.name
    property var biggestWindow: HyprlandData.biggestWindowForWorkspace(HyprlandData.monitors[root.monitor?.id]?.activeWorkspace.id)

    property bool vertical: false

    implicitWidth: root.vertical ? Appearance.sizes.verticalBarWidth : colLayout.implicitWidth
    implicitHeight: root.vertical ? Appearance.sizes.verticalBarWidth : Appearance.sizes.barHeight

    Item {
        id: verticalLayout
        visible: root.vertical
        anchors.centerIn: parent
        implicitWidth: Appearance.sizes.verticalBarWidth
        implicitHeight: Appearance.sizes.verticalBarWidth

        IconImage {
            id: appIcon
            anchors.centerIn: parent
            implicitSize: 22
            source: {
                const appId = (root.focusingThisMonitor && root.activeWindow?.activated && root.biggestWindow)
                              ? root.activeWindow?.appId : (root.biggestWindow?.class);
                return appId ? Quickshell.iconPath(AppSearch.guessIcon(appId), "") : "";
            }
            visible: source != ""
        }

        MaterialSymbol {
            anchors.centerIn: parent
            iconSize: Appearance.font.pixelSize.large
            color: Appearance.colors.colOnLayer0
            text: "desktop_windows"
            visible: !appIcon.visible
        }

        MouseArea {
            id: verticalHoverArea
            anchors.fill: parent
            hoverEnabled: true

            StyledPopup {
                hoverTarget: verticalHoverArea

                StyledText {
                    color: Appearance.colors.colOnLayer1
                    font.pixelSize: Appearance.font.pixelSize.small
                    text: {
                        const title = (root.focusingThisMonitor && root.activeWindow?.activated && root.biggestWindow)
                                      ? root.activeWindow?.title : (root.biggestWindow?.title) ?? "Desktop";
                        const app = (root.focusingThisMonitor && root.activeWindow?.activated && root.biggestWindow)
                                    ? root.activeWindow?.appId : (root.biggestWindow?.class) ?? "Desktop";
                        return `${app}\n${title}`;
                    }
                }
            }
        }
    }

    ColumnLayout {
        id: colLayout
        visible: !root.vertical

        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 0

        StyledText {
            Layout.fillWidth: true
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: Appearance.colors.colSubtext
            elide: Text.ElideRight
            text: root.focusingThisMonitor && root.activeWindow?.activated && root.biggestWindow
                  ? root.activeWindow?.appId : (root.biggestWindow?.class) ?? "Desktop"
        }

        StyledText {
            Layout.fillWidth: true
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colOnLayer0
            elide: Text.ElideRight
            text: root.focusingThisMonitor && root.activeWindow?.activated && root.biggestWindow
                  ? root.activeWindow?.title : (root.biggestWindow?.title) ?? `${"Workspace"} ${monitor?.activeWorkspace?.id ?? 1}`
        }
    }
}
