import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

/**
 * Material 3 tab with an optional leading icon.
 * https://m3.material.io/components/tabs
 *
 *   M3.Tab { text: "Stopwatch"; materialIcon: "timer" }
 *
 * variant: "secondary" (default) | "compact".
 */
TabButton {
    id: root

    property string variant: "secondary"
    property string materialIcon: ""
    readonly property bool compact: variant === "compact"
    readonly property color labelColor: !enabled
        ? ColorUtils.applyAlpha(Appearance.colors.colOnSurface, Appearance.stateLayer.disabledContent)
        : compact ? (checked ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnSurface)
        : (checked ? Appearance.colors.colPrimary : Appearance.colors.colOnLayer1)

    implicitWidth: compact ? contentRow.implicitWidth + Appearance.spacing.m * 2 : 0
    implicitHeight: compact ? Appearance.sizes.m3TabsCompactHeight : Appearance.sizes.m3TabsHeight

    background: Rectangle {
        anchors.fill: parent
        anchors.margins: root.compact ? 0 : Appearance.spacing.xxs
        radius: root.compact ? height / 2 : Appearance.rounding.normal
        color: root.hovered ? ColorUtils.stateLayer("transparent", root.labelColor, Appearance.stateLayer.hover) : "transparent"
        Behavior on color { animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this) }
    }

    contentItem: Item {
        RowLayout {
            id: contentRow
            anchors.centerIn: parent
            spacing: Appearance.spacing.xs

            MaterialSymbol {
                visible: root.materialIcon.length > 0
                text: root.materialIcon
                iconSize: Appearance.font.pixelSize.huge
                fill: root.checked ? 1 : 0
                color: root.labelColor
            }
            StyledText {
                text: root.text
                font.pixelSize: Appearance.font.pixelSize.small
                color: root.labelColor
                verticalAlignment: Text.AlignVCenter
            }
        }
    }
}
