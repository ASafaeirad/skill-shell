import QtQuick
import QtQuick.Controls
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

/**
 * Material 3 checkbox, with an optional label to its right.
 * https://m3.material.io/components/checkbox
 *
 *   M3.Checkbox { text: "Show hidden files"; checked: Config.options.x; onToggled: ... }
 *
 * tristate / checkState: from CheckBox; partial draws the indeterminate dash.
 * error: draws the box in the error colour.
 */
CheckBox {
    id: root

    property bool error: false

    readonly property bool filled: checkState !== Qt.Unchecked
    readonly property color accentColor: error ? Appearance.colors.colError : Appearance.colors.colPrimary
    readonly property color disabledColor: ColorUtils.applyAlpha(Appearance.colors.colOnSurface, Appearance.stateLayer.disabledContent)

    spacing: Appearance.spacing.xs
    padding: 0
    implicitHeight: Appearance.sizes.m3StateLayerSize

    PointingHandInteraction {}

    indicator: Item {
        implicitWidth: Appearance.sizes.m3StateLayerSize
        implicitHeight: Appearance.sizes.m3StateLayerSize
        x: root.leftPadding
        anchors.verticalCenter: parent.verticalCenter

        Rectangle {
            anchors.fill: parent
            radius: Appearance.rounding.full
            color: root.pressed ? ColorUtils.applyAlpha(root.filled ? root.accentColor : Appearance.colors.colOnSurface, Appearance.stateLayer.pressed)
                : root.hovered ? ColorUtils.applyAlpha(root.filled ? root.accentColor : Appearance.colors.colOnSurface, Appearance.stateLayer.hover)
                : "transparent"
        }

        Rectangle {
            anchors.centerIn: parent
            width: Appearance.sizes.m3SelectionControlSize
            height: Appearance.sizes.m3SelectionControlSize
            radius: Appearance.rounding.unsharpen
            color: !root.filled ? "transparent" : root.enabled ? root.accentColor : root.disabledColor
            border.width: root.filled ? 0 : Appearance.spacing.xxs
            border.color: !root.enabled ? root.disabledColor
                : root.error ? Appearance.colors.colError
                : Appearance.colors.colOnSurfaceVariant

            Behavior on color {
                animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
            }

            MaterialSymbol {
                anchors.centerIn: parent
                visible: root.filled
                text: root.checkState === Qt.PartiallyChecked ? "remove" : "check"
                iconSize: Appearance.font.pixelSize.normal
                fill: 1
                color: root.error ? Appearance.colors.colOnError : Appearance.colors.colOnPrimary
            }
        }
    }

    contentItem: StyledText {
        visible: root.text.length > 0
        text: root.text
        leftPadding: root.indicator.width + root.spacing
        verticalAlignment: Text.AlignVCenter
        color: root.enabled ? Appearance.colors.colOnSurface : root.disabledColor
    }
}
