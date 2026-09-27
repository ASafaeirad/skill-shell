import QtQuick
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

/**
 * Material 3 icon button.
 * https://m3.material.io/components/icon-buttons
 *
 *   M3.IconButton { materialIcon: "close"; tooltip: "Close"; onClicked: ... }
 *
 * variant: "standard" (default) | "filled" | "tonal" | "outlined"
 * size: "small" (default, 40) | "xsmall" (32), for dense rows
 * toggleable: acts as a toggle; `selected` then picks the selected colours
 *   and fills the icon. Leave it off for plain actions. `selected` is
 *   controlled: bind it to your state and flip that state in onClicked.
 * iconRotation: turns the icon, animated — for a chevron that flips when the
 *   thing it opens is open.
 */
RippleButton {
    id: root

    property string variant: "standard"
    property string size: "small"
    property string materialIcon: ""
    property string iconSource: ""
    property string tooltip: ""
    property bool toggleable: false
    property bool selected: false
    property real iconRotation: 0

    // A non-toggle filled or tonal button wears its selected colours.
    readonly property bool showSelected: toggleable ? selected : (variant === "filled" || variant === "tonal")
    readonly property bool hasContainer: variant !== "standard" && !(variant === "outlined" && !showSelected)
    readonly property color containerColor: variant === "filled" ? (showSelected ? Appearance.colors.colPrimary : Appearance.colors.colSurfaceContainerHighest)
        : variant === "tonal" ? (showSelected ? Appearance.colors.colSecondaryContainer : Appearance.colors.colSurfaceContainerHighest)
        : variant === "outlined" && showSelected ? Appearance.m3colors.m3inverseSurface
        : "transparent"
    readonly property color contentColor: !enabled ? ColorUtils.applyAlpha(Appearance.colors.colOnSurface, Appearance.stateLayer.disabledContent)
        : variant === "filled" ? (showSelected ? Appearance.colors.colOnPrimary : Appearance.colors.colPrimary)
        : variant === "tonal" ? (showSelected ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnSurfaceVariant)
        : variant === "outlined" && showSelected ? Appearance.m3colors.m3inverseOnSurface
        : variant === "standard" && toggleable && selected ? Appearance.colors.colPrimary
        : Appearance.colors.colOnSurfaceVariant

    readonly property real buttonSize: size === "xsmall" ? Appearance.sizes.m3IconButtonSizeXSmall : Appearance.sizes.m3IconButtonSize

    implicitWidth: buttonSize
    implicitHeight: buttonSize
    padding: 0
    buttonRadius: Appearance.rounding.full
    buttonRadiusPressed: Appearance.rounding.small
    opacity: 1

    toggled: toggleable && selected
    colBackground: containerColor
    colBackgroundHover: ColorUtils.stateLayer(containerColor, contentColor, Appearance.stateLayer.hover)
    colBackgroundToggled: containerColor
    colBackgroundToggledHover: colBackgroundHover
    colRipple: ColorUtils.applyAlpha(contentColor, Appearance.stateLayer.pressed * 2)
    colRippleToggled: colRipple
    buttonColor: !enabled ? (hasContainer ? ColorUtils.applyAlpha(Appearance.colors.colOnSurface, Appearance.stateLayer.disabledContainer) : "transparent")
        : hovered ? colBackgroundHover : colBackground
    colBorder: Appearance.colors.colOutlineVariant
    borderWidth: variant === "outlined" && !showSelected ? Appearance.sizes.m3OutlineWidth : 0

    contentItem: Item {
        MaterialSymbol {
            anchors.centerIn: parent
            visible: root.iconSource.length === 0
            text: root.materialIcon
            fill: root.toggleable && root.selected ? 1 : 0
            iconSize: root.size === "xsmall" ? Appearance.font.pixelSize.normal : Appearance.font.pixelSize.larger
            color: root.contentColor
            rotation: root.iconRotation

            Behavior on rotation {
                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
            }
        }
        StyledImage {
            anchors.centerIn: parent
            width: Appearance.font.pixelSize.larger
            height: width
            visible: root.iconSource.length > 0
            source: root.iconSource
        }
    }

    StyledToolTip {
        text: root.tooltip
        extraVisibleCondition: root.tooltip.length > 0
    }
}
