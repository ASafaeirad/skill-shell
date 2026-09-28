import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.modules.common

/**
 * Material 3 tabs for switching between related views.
 * https://m3.material.io/components/tabs
 *
 *   M3.Tabs { M3.Tab { text: "Pomodoro" } }
 *
 * variant: "secondary" (default) | "compact" (the region toolbar's pill layout).
 */
TabBar {
    id: root

    property string variant: "secondary"
    readonly property bool compact: variant === "compact"
    readonly property Item activeTab: currentIndex >= 0 ? itemAt(currentIndex) : null

    Layout.fillWidth: !compact
    Layout.alignment: compact ? Qt.AlignHCenter | Qt.AlignVCenter : Qt.AlignVCenter
    implicitWidth: compact
        ? contentChildren.reduce((sum, tab) => sum + tab.implicitWidth, 0) + spacing * Math.max(0, count - 1)
        : Appearance.sizes.m3TabsMinWidth
    implicitHeight: compact ? Appearance.sizes.m3TabsCompactHeight : Appearance.sizes.m3TabsHeight
    spacing: compact ? Appearance.spacing.xxs * 2 : 0

    background: Item {
        WheelHandler {
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            onWheel: event => {
                if (event.angleDelta.y < 0)
                    root.incrementCurrentIndex();
                else if (event.angleDelta.y > 0)
                    root.decrementCurrentIndex();
            }
        }

        Rectangle {
            visible: root.compact && root.activeTab
            color: Appearance.colors.colSecondaryContainer
            radius: height / 2
            x: root.activeTab?.x ?? 0
            width: root.activeTab?.width ?? 0
            height: parent.height
            Behavior on x { NumberAnimation { duration: Appearance.animation.elementMoveFast.duration } }
            Behavior on width { NumberAnimation { duration: Appearance.animation.elementMoveFast.duration } }
        }

        Rectangle {
            visible: !root.compact
            anchors.bottom: parent.bottom
            width: parent.width
            height: Appearance.sizes.m3DividerThickness
            color: Appearance.colors.colOutlineVariant
        }

        Rectangle {
            visible: !root.compact && root.activeTab
            anchors.bottom: parent.bottom
            color: Appearance.colors.colPrimary
            topLeftRadius: height
            topRightRadius: height
            height: Appearance.sizes.m3TabsIndicatorHeight
            x: (root.activeTab?.x ?? 0) + Appearance.spacing.s
            width: Math.max(0, (root.activeTab?.width ?? 0) - Appearance.spacing.s * 2)
            Behavior on x { NumberAnimation { duration: Appearance.animation.elementMoveFast.duration } }
            Behavior on width { NumberAnimation { duration: Appearance.animation.elementMoveFast.duration } }
        }
    }
}
