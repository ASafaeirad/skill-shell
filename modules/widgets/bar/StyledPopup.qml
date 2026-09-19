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
    property real shadowMargin: Appearance.sizes.elevationMargin
    property real shadowBlur: 0.9 * Appearance.sizes.elevationMargin
    property real shadowSpread: 1
    property real shadowRadius: backgroundRadius
    property color shadowColor: Appearance.colors.colShadow
    property vector2d shadowOffset: Qt.vector2d(0, 1)
    property real contentPadding: Appearance.spacing.s + Appearance.spacing.xxs
    property real backgroundRadius: Appearance.rounding.small
    property bool clipContent: false

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

        anchors.left: true
        anchors.right: false
        anchors.top: !Config.options.bar.bottom
        anchors.bottom: Config.options.bar.bottom

        implicitWidth: popupBackground.implicitWidth + root.shadowMargin * 2 + root.popupBackgroundMargin
        implicitHeight: popupBackground.implicitHeight + root.shadowMargin * 2 + root.popupBackgroundMargin

        mask: Region {
            item: popupBackground
        }

        exclusionMode: ExclusionMode.Ignore
        exclusiveZone: 0
        margins {
            left: {
                const targetPosition = root.QsWindow?.mapFromItem(root.hoverTarget, 0, 0).x ?? 0;
                const wantedPosition = targetPosition + (root.hoverTarget.width - popupWindow.implicitWidth) / 2;
                return popupWindow.boundedPosition(wantedPosition, popupWindow.availableWidth, popupWindow.implicitWidth);
            }
            top: Appearance.sizes.barHeight
            bottom: Appearance.sizes.barHeight
        }
        WlrLayershell.namespace: "quickshell:popup"
        WlrLayershell.layer: WlrLayer.Overlay

        StyledRectangularShadow {
            target: popupBackground
            blur: root.shadowBlur
            spread: root.shadowSpread
            radius: root.shadowRadius
            color: root.shadowColor
            offset: root.shadowOffset
        }

        Rectangle {
            id: popupBackground
            anchors {
                fill: parent
                leftMargin: root.shadowMargin + root.popupBackgroundMargin * (!popupWindow.anchors.left)
                rightMargin: root.shadowMargin + root.popupBackgroundMargin * (!popupWindow.anchors.right)
                topMargin: root.shadowMargin + root.popupBackgroundMargin * (!popupWindow.anchors.top)
                bottomMargin: root.shadowMargin + root.popupBackgroundMargin * (!popupWindow.anchors.bottom)
            }
            implicitWidth: root.contentItem.implicitWidth + root.contentPadding * 2
            implicitHeight: root.contentItem.implicitHeight + root.contentPadding * 2
            color: Appearance.m3colors.m3surfaceContainer
            radius: root.backgroundRadius
            clip: root.clipContent
            children: [root.contentItem]

            border.width: 1
            border.color: Appearance.colors.colLayer0Border
        }
    }
}
