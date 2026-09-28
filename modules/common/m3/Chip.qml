import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

/**
 * Material 3 chip.
 * https://m3.material.io/components/chips
 *
 *   M3.Chip { variant: "filter"; text: "Unread"; selected: inbox.unreadOnly; onClicked: ... }
 *
 * variant: "assist" (default) | "filter" | "input" | "suggestion"
 * selected: filter and input chips; a selected filter chip shows a check mark.
 *   Controlled: bind it and flip your state in onClicked.
 * removable: input chips get a trailing close icon that emits removeClicked().
 */
RippleButton {
    id: root

    property string variant: "assist"
    property string materialIcon: ""
    property bool selected: false
    property bool removable: variant === "input"
    // Keeps the selected choice readable when an in-progress action locks it.
    property bool readOnly: false
    property bool compact: false

    signal removeClicked()

    readonly property bool showSelected: selected && (variant === "filter" || variant === "input")
    readonly property string leadingIcon: variant === "filter" && showSelected ? "check" : materialIcon
    readonly property color containerColor: showSelected ? Appearance.colors.colSecondaryContainer : "transparent"
    readonly property color labelColor: !enabled ? ColorUtils.applyAlpha(Appearance.colors.colOnSurface, Appearance.stateLayer.disabledContent)
        : showSelected ? Appearance.colors.colOnSecondaryContainer
        : Appearance.colors.colOnSurfaceVariant
    readonly property color iconColor: !enabled ? labelColor
        : showSelected ? Appearance.colors.colOnSecondaryContainer
        : Appearance.colors.colPrimary

    implicitHeight: compact ? Appearance.sizes.m3ChipHeightCompact : Appearance.sizes.m3ChipHeight
    leftPadding: leadingIcon.length > 0 ? Appearance.spacing.s : Appearance.spacing.m
    rightPadding: removable ? Appearance.spacing.s : Appearance.spacing.m
    buttonRadius: Appearance.rounding.verysmall
    opacity: 1

    colBackground: containerColor
    colBackgroundHover: readOnly ? containerColor : ColorUtils.stateLayer(containerColor, labelColor, Appearance.stateLayer.hover)
    pointingHandCursor: !readOnly
    rippleEnabled: !readOnly
    colRipple: ColorUtils.applyAlpha(labelColor, Appearance.stateLayer.pressed * 2)
    buttonColor: !enabled ? (showSelected ? ColorUtils.applyAlpha(Appearance.colors.colOnSurface, Appearance.stateLayer.disabledContainer) : "transparent")
        : hovered ? colBackgroundHover : colBackground
    colBorder: enabled ? Appearance.colors.colOutlineVariant : ColorUtils.applyAlpha(Appearance.colors.colOnSurface, Appearance.stateLayer.disabledContainer)
    borderWidth: showSelected ? 0 : Appearance.sizes.m3OutlineWidth

    contentItem: RowLayout {
        spacing: Appearance.spacing.s

        MaterialSymbol {
            visible: root.leadingIcon.length > 0
            text: root.leadingIcon
            iconSize: Appearance.font.pixelSize.normal
            color: root.iconColor
        }
        StyledText {
            text: root.text
            color: root.labelColor
            font.pixelSize: Appearance.font.pixelSize.smallie
            elide: Text.ElideRight
            Layout.fillWidth: true
        }
        MaterialSymbol {
            visible: root.removable
            text: "close"
            iconSize: Appearance.font.pixelSize.normal
            color: root.labelColor

            MouseArea {
                anchors.fill: parent
                anchors.margins: -Appearance.spacing.xs
                enabled: root.enabled
                cursorShape: Qt.PointingHandCursor
                onClicked: root.removeClicked()
            }
        }
    }
}
