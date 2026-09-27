import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

/**
 * Material 3 list item: one or two lines with optional leading and trailing parts.
 * https://m3.material.io/components/lists
 *
 *   M3.ListItem {
 *       leadingIcon: "wifi"
 *       text: "Home network"
 *       supportingText: "Connected"
 *       onClicked: ...
 *       M3.Switch { checked: true }      // children go to the trailing slot
 *   }
 *
 * text is the headline. trailingText is the short trailing label (a count, a time).
 * interactive: false turns it into a static row with no state layer or cursor.
 */
RippleButton {
    id: root

    property string supportingText: ""
    property string leadingIcon: ""
    property string trailingIcon: ""
    property string trailingText: ""
    property bool interactive: true
    default property alias trailingData: trailingSlot.data

    readonly property color headlineColor: enabled ? Appearance.colors.colOnSurface
        : ColorUtils.applyAlpha(Appearance.colors.colOnSurface, Appearance.stateLayer.disabledContent)
    readonly property color supportingColor: enabled ? Appearance.colors.colOnSurfaceVariant
        : ColorUtils.applyAlpha(Appearance.colors.colOnSurface, Appearance.stateLayer.disabledContent)

    implicitHeight: supportingText.length > 0 ? Appearance.sizes.m3ListItemTwoLineHeight : Appearance.sizes.m3ListItemOneLineHeight
    leftPadding: Appearance.spacing.lg
    rightPadding: Appearance.spacing.xl
    buttonRadius: Appearance.rounding.small
    opacity: 1

    pointingHandCursor: interactive
    rippleEnabled: interactive
    colBackground: "transparent"
    colBackgroundHover: interactive ? ColorUtils.stateLayer("transparent", Appearance.colors.colOnSurface, Appearance.stateLayer.hover) : "transparent"
    colRipple: ColorUtils.applyAlpha(Appearance.colors.colOnSurface, Appearance.stateLayer.pressed * 2)
    buttonColor: hovered ? colBackgroundHover : colBackground

    contentItem: RowLayout {
        spacing: Appearance.spacing.lg

        MaterialSymbol {
            visible: root.leadingIcon.length > 0
            text: root.leadingIcon
            iconSize: Appearance.font.pixelSize.hugeass
            color: root.supportingColor
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                Layout.fillWidth: true
                text: root.text
                color: root.headlineColor
                font.pixelSize: Appearance.font.pixelSize.normal
                elide: Text.ElideRight
            }
            StyledText {
                Layout.fillWidth: true
                visible: root.supportingText.length > 0
                text: root.supportingText
                color: root.supportingColor
                font.pixelSize: Appearance.font.pixelSize.smallie
                elide: Text.ElideRight
            }
        }

        StyledText {
            visible: root.trailingText.length > 0
            text: root.trailingText
            color: root.supportingColor
            font.pixelSize: Appearance.font.pixelSize.smaller
        }
        MaterialSymbol {
            visible: root.trailingIcon.length > 0
            text: root.trailingIcon
            iconSize: Appearance.font.pixelSize.hugeass
            color: root.supportingColor
        }
        RowLayout {
            id: trailingSlot
            visible: children.length > 0
            spacing: Appearance.spacing.s
        }
    }
}
