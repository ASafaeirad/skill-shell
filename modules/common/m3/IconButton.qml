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
 * size: "small" (default, 40) | "medium" (44) | "xsmall" (32) | "compact" (20, inline actions) | "xlarge" (120)
 * shape: "round" (default) | "square", with rounded corners
 * toggleable: acts as a toggle; `selected` then picks the selected colours
 *   and fills the icon. Leave it off for plain actions. `selected` is
 *   controlled: bind it to your state and flip that state in onClicked.
 * selectedVariant: "" (default, the variant's own selected colours) | "tonal";
 *   a toggle that wears the tonal selected container when selected, as the
 *   standard icon buttons in a toolbar do.
 * iconFilled: fills an action glyph independently of toggle selection.
 * iconRotation: turns the icon, animated — for a chevron that flips when the
 *   thing it opens is open.
 * error: a destructive action (delete, move to trash). M3's error roles stand in
 *   for the accent ones, so the icon reads red wherever the variant would be
 *   primary. Same meaning as Checkbox's error.
 * dotColor: a colour dot in place of the icon, for a button that picks or stands
 *   for a colour (a palette swatch). Pair it with toggleable + selected and the
 *   round container becomes the swatch's selection ring.
 */
RippleButton {
    id: root

    property string variant: "standard"
    property string selectedVariant: ""
    property string size: "small"
    property string shape: "round"
    property string materialIcon: ""
    property bool iconFilled: false
    property string iconSource: ""
    property string tooltip: ""
    property bool toggleable: false
    property bool selected: false
    property real iconRotation: 0
    property bool error: false
    property color dotColor: "transparent"

    readonly property bool hasDot: dotColor.a > 0

    // Avoid on<Color> names: QML treats their bindings as signal handlers.
    // A destructive action swaps M3's accent roles for the error ones.
    readonly property color accentColor: error ? Appearance.colors.colError : Appearance.colors.colPrimary
    readonly property color accentContentColor: error ? Appearance.colors.colOnError : Appearance.colors.colOnPrimary
    readonly property color accentContainerColor: error ? Appearance.colors.colErrorContainer : Appearance.colors.colSecondaryContainer
    readonly property color accentContainerContentColor: error ? Appearance.colors.colOnErrorContainer : Appearance.colors.colOnSecondaryContainer
    readonly property color neutralContentColor: error ? Appearance.colors.colError : Appearance.colors.colOnSurfaceVariant

    // The variant whose colours are drawn: selectedVariant takes over while selected.
    readonly property string colorVariant: toggleable && selected && selectedVariant.length > 0 ? selectedVariant : variant
    // A non-toggle filled or tonal button wears its selected colours.
    readonly property bool showSelected: toggleable ? selected : (colorVariant === "filled" || colorVariant === "tonal")
    readonly property bool hasContainer: colorVariant !== "standard" && !(colorVariant === "outlined" && !showSelected)
    readonly property color containerColor: colorVariant === "filled" ? (showSelected ? accentColor : Appearance.colors.colSurfaceContainerHighest)
        : colorVariant === "tonal" ? (showSelected ? accentContainerColor : Appearance.colors.colSurfaceContainerHighest)
        : colorVariant === "outlined" && showSelected ? Appearance.m3colors.m3inverseSurface
        : "transparent"
    readonly property color contentColor: !enabled ? ColorUtils.applyAlpha(Appearance.colors.colOnSurface, Appearance.stateLayer.disabledContent)
        : colorVariant === "filled" ? (showSelected ? accentContentColor : accentColor)
        : colorVariant === "tonal" ? (showSelected ? accentContainerContentColor : neutralContentColor)
        : colorVariant === "outlined" && showSelected ? Appearance.m3colors.m3inverseOnSurface
        : colorVariant === "standard" && toggleable && selected ? accentColor
        : neutralContentColor

    readonly property real buttonSize: size === "xlarge" ? Appearance.sizes.m3IconButtonSizeXLarge
        : size === "medium" ? Appearance.sizes.m3IconButtonSizeMedium
        : size === "compact" ? Appearance.sizes.m3IconButtonSizeCompact
        : size === "xsmall" ? Appearance.sizes.m3IconButtonSizeXSmall : Appearance.sizes.m3IconButtonSize

    implicitWidth: buttonSize
    implicitHeight: buttonSize
    padding: 0
    buttonRadius: shape === "square" ? (size === "medium" ? Appearance.rounding.normal : Appearance.rounding.verylarge) : Appearance.rounding.full
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
        : activeFocus ? ColorUtils.stateLayer(containerColor, contentColor, Appearance.stateLayer.focus)
        : hovered ? colBackgroundHover : colBackground
    colBorder: Appearance.colors.colOutlineVariant
    borderWidth: variant === "outlined" && !showSelected ? Appearance.sizes.m3OutlineWidth : 0

    contentItem: Item {
        Rectangle {
            anchors.centerIn: parent
            visible: root.hasDot
            width: Appearance.spacing.m
            height: width
            radius: Appearance.rounding.full
            color: root.dotColor
        }
        MaterialSymbol {
            anchors.centerIn: parent
            visible: root.iconSource.length === 0 && !root.hasDot
            text: root.materialIcon
            fill: root.iconFilled || (root.toggleable && root.selected) ? 1 : 0
            iconSize: root.size === "xlarge" ? Appearance.sizes.m3IconButtonIconSizeXLarge
                : root.size === "medium" ? Appearance.sizes.m3IconButtonIconSizeMedium
                : root.size === "xsmall" || root.size === "compact" ? Appearance.font.pixelSize.normal : Appearance.font.pixelSize.larger
            color: root.contentColor
            rotation: root.iconRotation

            Behavior on rotation {
                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
            }
        }
        StyledImage {
            anchors.centerIn: parent
            width: root.buttonSize - Appearance.spacing.xs * 2
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
