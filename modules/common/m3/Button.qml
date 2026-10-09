import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

/**
 * Material 3 common button.
 * https://m3.material.io/components/buttons
 *
 *   M3.Button { variant: "tonal"; text: "Retry"; materialIcon: "refresh"; onClicked: ... }
 *
 * variant: "filled" (default) | "tonal" | "outlined" | "text" | "elevated"
 * variant "indicator": shell workspace dot, with a transparent container so
 *   the workspace group's occupied and animated active markers remain visible.
 * occupied: indicator dot uses on-secondary-container instead of inactive text.
 *   selected uses on-primary. Geometry comes from the m3Workspace tokens.
 * shape: "round" (default) | "square"; M3's square shape keeps small corners,
 *   for a button that sits in a grid of equal cells (a calendar day).
 * selected: toggle-button state; a selected button uses selectedVariant colours.
 * selectedVariant: "filled" (default) | "tonal"; colour treatment when selected.
 * toggleable: the button is a toggle, so its unselected state wears the
 *   neutral toggle colours (surface container, on-surface-variant) instead of
 *   the variant's own, as M3 specifies. Leave it off for a plain action.
 * trailingText: a smaller figure after the label, such as a size ("~42 MB").
 * tileLayout: a 56px, leading-aligned quick settings button with a supporting
 * line and the shell's layer surface for its inactive container.
 * leadingAction: an independent icon action on a tile, with leadingSelected.
 * content: the button's content slot, for the rare button whose label is not
 *   text (the bar's status pill is a row of indicator icons). It replaces the
 *   icon/label row and keeps the container, padding and state layers. Colour
 *   what you put in it with the button's own `contentColor`.
 * externalHover: draw the hover state layer while a larger region around the
 *   button is hovered, for a button that is the affordance of a whole area.
 * error: a destructive or error-recovery action. M3's error roles stand in for
 *   the accent ones, so a filled button is the error container and a text or
 *   outlined one reads red. Same meaning as Checkbox's error.
 */
RippleButton {
    id: root

    property string variant: "filled"
    property string shape: "round"
    property bool occupied: false
    property string materialIcon: ""
    property bool selected: false
    property string selectedVariant: "filled"
    property bool toggleable: false
    property string trailingText: ""
    property string supportingText: ""
    property bool tileLayout: false
    property var leadingAction: null
    property bool leadingSelected: false
    property Component content: null
    property bool externalHover: false
    property bool error: false

    // Avoid on<Color> names: QML treats their bindings as signal handlers.
    // A destructive action swaps M3's accent roles for the error ones.
    readonly property color accentColor: error ? Appearance.colors.colError : Appearance.colors.colPrimary
    readonly property color accentContentColor: error ? Appearance.colors.colOnError : Appearance.colors.colOnPrimary
    readonly property color accentContainerColor: error ? Appearance.colors.colErrorContainer : Appearance.colors.colSecondaryContainer
    readonly property color accentContainerContentColor: error ? Appearance.colors.colOnErrorContainer : Appearance.colors.colOnSecondaryContainer

    readonly property bool showHover: hovered || externalHover

    // An unselected toggle drops to the neutral surface roles, whatever its variant.
    readonly property bool unselectedToggle: toggleable && !selected

    readonly property bool hasContainer: variant === "filled" || variant === "tonal" || variant === "elevated"
    readonly property color containerColor: variant === "indicator" ? "transparent" : unselectedToggle ? (variant === "filled" || variant === "tonal" ? Appearance.colors.colSurfaceContainerHighest
            : variant === "elevated" ? Appearance.colors.colSurfaceContainerLow
            : "transparent")
        : selected ? (selectedVariant === "tonal" ? accentContainerColor : accentColor)
        : tileLayout ? Appearance.colors.colLayer2
        : variant === "filled" ? accentColor
        : variant === "tonal" ? accentContainerColor
        : variant === "elevated" ? Appearance.colors.colSurfaceContainerLow
        : "transparent"
    readonly property color contentColor: !enabled ? ColorUtils.applyAlpha(Appearance.colors.colOnSurface, Appearance.stateLayer.disabledContent)
        : variant === "indicator" ? (selected ? Appearance.m3colors.m3onPrimary
            : occupied ? Appearance.m3colors.m3onSecondaryContainer : Appearance.colors.colOnLayer1Inactive)
        : unselectedToggle ? Appearance.colors.colOnSurfaceVariant
        : selected ? (selectedVariant === "tonal" ? accentContainerContentColor : accentContentColor)
        : tileLayout ? Appearance.colors.colOnLayer2
        : variant === "filled" ? accentContentColor
        : variant === "tonal" ? accentContainerContentColor
        : accentColor

    implicitWidth: variant === "indicator" ? Appearance.sizes.m3WorkspaceButtonWidth : implicitContentWidth + leftPadding + rightPadding
    implicitHeight: variant === "indicator" ? Appearance.sizes.barHeight : tileLayout ? Appearance.sizes.m3QuickTileHeight : Appearance.sizes.m3ButtonHeight
    leftPadding: variant === "indicator" ? 0 : tileLayout ? Appearance.spacing.xs : (materialIcon.length > 0 ? Appearance.spacing.lg : Appearance.spacing.xl)
    rightPadding: variant === "indicator" ? 0 : tileLayout ? Appearance.spacing.xs : Appearance.spacing.xl
    buttonRadius: tileLayout ? Appearance.rounding.large
        : shape === "square" ? Appearance.rounding.small
        : Appearance.rounding.full
    buttonRadiusPressed: shape === "square" ? Appearance.rounding.verysmall : Appearance.rounding.small
    opacity: 1

    toggled: selected
    colBackground: containerColor
    colBackgroundHover: ColorUtils.stateLayer(containerColor, contentColor, Appearance.stateLayer.hover)
    colBackgroundToggled: containerColor
    colBackgroundToggledHover: colBackgroundHover
    colRipple: ColorUtils.applyAlpha(contentColor, Appearance.stateLayer.pressed * 2)
    colRippleToggled: colRipple
    buttonColor: !enabled ? (hasContainer ? ColorUtils.applyAlpha(Appearance.colors.colOnSurface, Appearance.stateLayer.disabledContainer) : "transparent")
        : showHover ? colBackgroundHover : colBackground
    colBorder: enabled ? Appearance.colors.colOutlineVariant : ColorUtils.applyAlpha(Appearance.colors.colOnSurface, Appearance.stateLayer.disabledContainer)
    borderWidth: variant === "outlined" && !selected ? Appearance.sizes.m3OutlineWidth : 0

    StyledRectangularShadow {
        target: root.background
        visible: root.variant === "elevated" && root.enabled
        z: -1
    }

    // The content stays centred when the button is stretched wider than it;
    // quick tiles fill the width so the icon and labels start at the leading edge.
    contentItem: Item {
        implicitWidth: root.variant === "indicator" ? Appearance.sizes.m3WorkspaceDotSize : root.content ? customContent.implicitWidth : contentRow.implicitWidth
        implicitHeight: root.variant === "indicator" ? Appearance.sizes.m3WorkspaceDotSize : root.content ? customContent.implicitHeight : contentRow.implicitHeight

        Rectangle {
            visible: root.variant === "indicator"
            anchors.centerIn: parent
            width: Appearance.sizes.m3WorkspaceDotSize
            height: width
            radius: Appearance.rounding.full
            color: root.contentColor
        }

        Loader {
            id: customContent

            anchors.centerIn: parent
            sourceComponent: root.content
        }

        RowLayout {
            id: contentRow

            visible: !root.content && root.variant !== "indicator"
            anchors.centerIn: parent
            width: root.tileLayout ? parent.width : Math.min(implicitWidth, parent.width)
            spacing: root.tileLayout ? Appearance.sizes.m3QuickTileIconGap : Appearance.spacing.s

            IconButton {
                visible: root.tileLayout && root.leadingAction !== null && root.materialIcon.length > 0
                variant: "filled"
                toggleable: true
                selected: root.leadingSelected
                buttonRadius: root.leadingSelected ? Appearance.rounding.normal : Appearance.rounding.full
                Layout.preferredWidth: Appearance.sizes.m3QuickTileIconSize
                Layout.preferredHeight: Appearance.sizes.m3QuickTileIconSize
                materialIcon: root.materialIcon
                onClicked: if (root.leadingAction) root.leadingAction()
            }
            MaterialSymbol {
                visible: (!root.tileLayout || root.leadingAction === null) && root.materialIcon.length > 0
                text: root.materialIcon
                fill: root.selected ? 1 : 0
                iconSize: Appearance.font.pixelSize.larger
                color: root.contentColor
                Layout.preferredWidth: root.tileLayout ? Appearance.sizes.m3QuickTileIconSize : implicitWidth
                horizontalAlignment: Text.AlignHCenter
            }
            ColumnLayout {
                visible: root.text.length > 0
                Layout.fillWidth: true
                spacing: 0
                StyledText {
                    text: root.text
                    color: root.contentColor
                    font.pixelSize: root.tileLayout ? Appearance.font.pixelSize.smallie : Appearance.font.pixelSize.small
                    font.weight: root.font.weight // so a caller can emphasise the label
                    Layout.fillWidth: true
                    horizontalAlignment: root.tileLayout ? Text.AlignLeft : Text.AlignHCenter
                    elide: Text.ElideRight
                }
                StyledText {
                    visible: root.supportingText.length > 0
                    text: root.supportingText
                    color: root.contentColor
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
            }
            StyledText {
                visible: root.trailingText.length > 0
                text: root.trailingText
                color: root.contentColor
                font.pixelSize: Appearance.font.pixelSize.smaller
                font.features: ({
                        "tnum": 1
                    })
            }
        }
    }
}
