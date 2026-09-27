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
 */
RippleButton {
    id: root

    property string variant: "filled"
    property string materialIcon: ""
    property bool selected: false
    property string trailingText: ""

    readonly property bool hasContainer: variant === "filled" || variant === "tonal" || variant === "elevated"
    readonly property color containerColor: selected ? Appearance.colors.colPrimary
        : variant === "filled" ? Appearance.colors.colPrimary
        : variant === "tonal" ? Appearance.colors.colSecondaryContainer
        : variant === "elevated" ? Appearance.colors.colSurfaceContainerLow
        : "transparent"
    readonly property color contentColor: !enabled ? ColorUtils.applyAlpha(Appearance.colors.colOnSurface, Appearance.stateLayer.disabledContent)
        : selected ? Appearance.colors.colOnPrimary
        : variant === "filled" ? Appearance.colors.colOnPrimary
        : variant === "tonal" ? Appearance.colors.colOnSecondaryContainer
        : Appearance.colors.colPrimary

    implicitHeight: Appearance.sizes.m3ButtonHeight
    leftPadding: materialIcon.length > 0 ? Appearance.spacing.lg : Appearance.spacing.xl
    rightPadding: Appearance.spacing.xl
    buttonRadius: Appearance.rounding.full
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

    // The row stays centred when the button is stretched wider than its content.
    contentItem: Item {
        implicitWidth: contentRow.implicitWidth
        implicitHeight: contentRow.implicitHeight

        RowLayout {
            id: contentRow

            anchors.centerIn: parent
            width: Math.min(implicitWidth, parent.width)
            spacing: Appearance.spacing.s

            MaterialSymbol {
                visible: root.materialIcon.length > 0
                text: root.materialIcon
                fill: root.selected ? 1 : 0
                iconSize: Appearance.font.pixelSize.larger
                color: root.contentColor
            }
            StyledText {
                visible: root.text.length > 0
                text: root.text
                color: root.contentColor
                font.pixelSize: Appearance.font.pixelSize.small
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
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
