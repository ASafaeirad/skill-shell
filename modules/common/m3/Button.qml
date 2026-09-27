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
 * selected: toggle-button state; a selected button takes the filled colours.
 * trailingText: a smaller figure after the label, such as a size ("~42 MB").
 * tileLayout: a 56px, leading-aligned quick settings button with a supporting
 * line and the shell's layer surface for its inactive container.
 * leadingAction: an independent icon action on a tile, with leadingSelected.
 */
RippleButton {
    id: root

    property string variant: "filled"
    property string materialIcon: ""
    property bool selected: false
    property string trailingText: ""
    property string supportingText: ""
    property bool tileLayout: false
    property var leadingAction: null
    property bool leadingSelected: false

    readonly property bool hasContainer: variant === "filled" || variant === "tonal" || variant === "elevated"
    readonly property color containerColor: selected ? Appearance.colors.colPrimary
        : tileLayout ? Appearance.colors.colLayer2
        : variant === "filled" ? Appearance.colors.colPrimary
        : variant === "tonal" ? Appearance.colors.colSecondaryContainer
        : variant === "elevated" ? Appearance.colors.colSurfaceContainerLow
        : "transparent"
    readonly property color contentColor: !enabled ? ColorUtils.applyAlpha(Appearance.colors.colOnSurface, Appearance.stateLayer.disabledContent)
        : selected ? Appearance.colors.colOnPrimary
        : tileLayout ? Appearance.colors.colOnLayer2
        : variant === "filled" ? Appearance.colors.colOnPrimary
        : variant === "tonal" ? Appearance.colors.colOnSecondaryContainer
        : Appearance.colors.colPrimary

    implicitHeight: tileLayout ? Appearance.sizes.m3QuickTileHeight : Appearance.sizes.m3ButtonHeight
    leftPadding: tileLayout ? Appearance.spacing.xs : (materialIcon.length > 0 ? Appearance.spacing.lg : Appearance.spacing.xl)
    rightPadding: tileLayout ? Appearance.spacing.xs : Appearance.spacing.xl
    buttonRadius: tileLayout ? Appearance.rounding.large : Appearance.rounding.full
    buttonRadiusPressed: Appearance.rounding.small
    opacity: 1

    toggled: selected
    colBackground: containerColor
    colBackgroundHover: ColorUtils.stateLayer(containerColor, contentColor, Appearance.stateLayer.hover)
    colBackgroundToggled: containerColor
    colBackgroundToggledHover: colBackgroundHover
    colRipple: ColorUtils.applyAlpha(contentColor, Appearance.stateLayer.pressed * 2)
    colRippleToggled: colRipple
    buttonColor: !enabled ? (hasContainer ? ColorUtils.applyAlpha(Appearance.colors.colOnSurface, Appearance.stateLayer.disabledContainer) : "transparent")
        : hovered ? colBackgroundHover : colBackground
    colBorder: enabled ? Appearance.colors.colOutlineVariant : ColorUtils.applyAlpha(Appearance.colors.colOnSurface, Appearance.stateLayer.disabledContainer)
    borderWidth: variant === "outlined" && !selected ? Appearance.sizes.m3OutlineWidth : 0

    StyledRectangularShadow {
        target: root.background
        visible: root.variant === "elevated" && root.enabled
        z: -1
    }

    // Quick tiles fill the width so the icon and labels start at the leading edge.
    contentItem: Item {
        implicitWidth: contentRow.implicitWidth
        implicitHeight: contentRow.implicitHeight

        RowLayout {
            id: contentRow

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
