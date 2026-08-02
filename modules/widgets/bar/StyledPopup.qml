import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland

LazyLoader {
    id: root

    property Item hoverTarget
    default property Item contentItem
    property real popupBackgroundMargin: 0

    active: hoverTarget && hoverTarget.containsMouse

    component: PanelWindow {
        id: popupWindow
        color: "transparent"

        readonly property real availableWidth: screen?.width ?? root.QsWindow?.screen?.width ?? 0
        readonly property real availableHeight: screen?.height ?? root.QsWindow?.screen?.height ?? 0

        function boundedPosition(wantedPosition, availableSize, popupSize) {
            if (availableSize <= 0)
                return wantedPosition;
            return Math.max(0, Math.min(wantedPosition, availableSize - popupSize));
        }

        anchors.left: !Config.options.bar.vertical || (Config.options.bar.vertical && !Config.options.bar.bottom)
        anchors.right: Config.options.bar.vertical && Config.options.bar.bottom
        anchors.top: Config.options.bar.vertical || (!Config.options.bar.vertical && !Config.options.bar.bottom)
        anchors.bottom: !Config.options.bar.vertical && Config.options.bar.bottom

        implicitWidth: popupBackground.implicitWidth + Appearance.sizes.elevationMargin * 2 + root.popupBackgroundMargin
        implicitHeight: popupBackground.implicitHeight + Appearance.sizes.elevationMargin * 2 + root.popupBackgroundMargin

        mask: Region {
            item: popupBackground
        }

        exclusionMode: ExclusionMode.Ignore
        exclusiveZone: 0
        margins {
            left: {
                if (!Config.options.bar.vertical) {
                    const targetPosition = root.QsWindow?.mapFromItem(root.hoverTarget, 0, 0).x ?? 0;
                    const wantedPosition = targetPosition + (root.hoverTarget.width - popupWindow.implicitWidth) / 2;
                    return popupWindow.boundedPosition(wantedPosition, popupWindow.availableWidth, popupWindow.implicitWidth);
                }
                return Appearance.sizes.verticalBarWidth;
            }
            top: {
                if (!Config.options.bar.vertical)
                    return Appearance.sizes.barHeight;
                const targetPosition = root.QsWindow?.mapFromItem(root.hoverTarget, 0, 0).y ?? 0;
                const wantedPosition = targetPosition + (root.hoverTarget.height - popupWindow.implicitHeight) / 2;
                return popupWindow.boundedPosition(wantedPosition, popupWindow.availableHeight, popupWindow.implicitHeight);
            }
            right: Appearance.sizes.verticalBarWidth
            bottom: Appearance.sizes.barHeight
        }
        WlrLayershell.namespace: "quickshell:popup"
        WlrLayershell.layer: WlrLayer.Overlay

        StyledRectangularShadow {
            target: popupBackground
        }

        Rectangle {
            id: popupBackground
            readonly property real margin: 10
            anchors {
                fill: parent
                leftMargin: Appearance.sizes.elevationMargin + root.popupBackgroundMargin * (!popupWindow.anchors.left)
                rightMargin: Appearance.sizes.elevationMargin + root.popupBackgroundMargin * (!popupWindow.anchors.right)
                topMargin: Appearance.sizes.elevationMargin + root.popupBackgroundMargin * (!popupWindow.anchors.top)
                bottomMargin: Appearance.sizes.elevationMargin + root.popupBackgroundMargin * (!popupWindow.anchors.bottom)
            }
            implicitWidth: root.contentItem.implicitWidth + margin * 2
            implicitHeight: root.contentItem.implicitHeight + margin * 2
            color: Appearance.m3colors.m3surfaceContainer
            radius: Appearance.rounding.small
            children: [root.contentItem]

            border.width: 1
            border.color: Appearance.colors.colLayer0Border
        }
    }
}
