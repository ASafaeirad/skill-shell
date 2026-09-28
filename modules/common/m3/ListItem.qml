import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
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
 * text is the headline. overline is the small label above it (a category).
 * trailingText is the short trailing label (a count, a time).
 * Leading element: leadingIcon (a symbol), leadingIconSource (an image, such as
 *   an application icon) or leadingText (a glyph, such as an emoji).
 * selected: M3's selected state (secondary container). Controlled, like
 *   everywhere else: bind it, e.g. to the keyboard-current row of a result list.
 * textFormat: Text.StyledText for a headline with inline markup (highlighted
 *   matches); monospace sets the headline in the monospace family.
 * headlineLeadingData: small items drawn before the headline (a favicon).
 * supportingData: items drawn under the headline (an image preview); the item
 *   grows to fit them.
 * interactive: false turns it into a static row with no state layer or cursor.
 * compact: uses tighter spacing for narrow panels with a one-line headline.
 * density: the Material density scale, 0 (default) to -3; each step takes
 *   Appearance.sizes.m3DensityStep off the height, for long scanned lists.
 */
RippleButton {
    id: root

    property string supportingText: ""
    property string overline: ""
    property string leadingIcon: ""
    property url leadingIconSource
    property string leadingText: ""
    property string trailingIcon: ""
    property string trailingText: ""
    property bool selected: false
    property int textFormat: Text.PlainText
    property bool monospace: false
    property bool interactive: true
    property bool compact: false
    property int density: 0
    default property alias trailingData: trailingSlot.data
    property alias headlineLeadingData: headlineLeadingSlot.data
    property alias supportingData: supportingSlot.data

    readonly property color containerColor: selected ? Appearance.colors.colSecondaryContainer : "transparent"
    readonly property color headlineColor: !enabled ? ColorUtils.applyAlpha(Appearance.colors.colOnSurface, Appearance.stateLayer.disabledContent)
        : selected ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnSurface
    readonly property color supportingColor: !enabled ? ColorUtils.applyAlpha(Appearance.colors.colOnSurface, Appearance.stateLayer.disabledContent)
        : selected ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnSurfaceVariant
    readonly property bool hasLeading: leadingIcon.length > 0 || leadingIconSource != "" || leadingText.length > 0
    readonly property real minimumHeight: ((supportingText.length > 0 || overline.length > 0) ? Appearance.sizes.m3ListItemTwoLineHeight
        : compact ? Appearance.sizes.m3ListItemCompactHeight : Appearance.sizes.m3ListItemOneLineHeight)
        + Math.max(-3, Math.min(0, density)) * Appearance.sizes.m3DensityStep

    implicitHeight: Math.max(minimumHeight, (contentItem?.implicitHeight ?? 0) + topPadding + bottomPadding)
    leftPadding: compact ? Appearance.spacing.s : Appearance.spacing.lg
    rightPadding: compact ? Appearance.spacing.s : Appearance.spacing.xl
    buttonRadius: Appearance.rounding.small
    opacity: 1

    pointingHandCursor: interactive
    rippleEnabled: interactive
    colBackground: containerColor
    colBackgroundHover: interactive ? ColorUtils.stateLayer(containerColor, headlineColor, Appearance.stateLayer.hover) : containerColor
    colRipple: ColorUtils.applyAlpha(headlineColor, Appearance.stateLayer.pressed * 2)
    buttonColor: hovered ? colBackgroundHover : colBackground

    contentItem: RowLayout {
        spacing: root.compact ? Appearance.spacing.s : Appearance.spacing.lg

        Item {
            visible: root.hasLeading
            implicitWidth: Math.max(leadingSymbol.visible ? leadingSymbol.implicitWidth : 0,
                leadingImage.visible ? leadingImage.implicitWidth : 0,
                leadingGlyph.visible ? leadingGlyph.implicitWidth : 0)
            implicitHeight: Math.max(leadingSymbol.visible ? leadingSymbol.implicitHeight : 0,
                leadingImage.visible ? leadingImage.implicitHeight : 0,
                leadingGlyph.visible ? leadingGlyph.implicitHeight : 0)

            MaterialSymbol {
                id: leadingSymbol
                anchors.centerIn: parent
                visible: root.leadingIcon.length > 0 && root.leadingIconSource == ""
                text: root.leadingIcon
                iconSize: root.compact ? Appearance.font.pixelSize.larger : Appearance.font.pixelSize.hugeass
                color: root.supportingColor
            }
            IconImage {
                id: leadingImage
                anchors.centerIn: parent
                visible: root.leadingIconSource != ""
                asynchronous: true
                source: root.leadingIconSource
                implicitSize: Appearance.sizes.m3ListItemLeadingImageSize
                mipmap: true
            }
            StyledText {
                id: leadingGlyph
                anchors.centerIn: parent
                visible: root.leadingText.length > 0 && !leadingSymbol.visible && !leadingImage.visible
                text: root.leadingText
                color: root.headlineColor
                font.pixelSize: Appearance.font.pixelSize.larger
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                Layout.fillWidth: true
                visible: root.overline.length > 0
                text: root.overline
                color: root.supportingColor
                font.pixelSize: Appearance.font.pixelSize.smaller
                elide: Text.ElideRight
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 0

                RowLayout {
                    id: headlineLeadingSlot
                    // Gap only while something in the slot is showing
                    Layout.rightMargin: implicitWidth > 0 ? Appearance.spacing.xs : 0
                    visible: children.length > 0
                    spacing: Appearance.spacing.xs
                }
                StyledText {
                    Layout.fillWidth: true
                    text: root.text
                    textFormat: root.textFormat
                    color: root.headlineColor
                    font.pixelSize: Appearance.font.pixelSize.normal
                    font.family: root.monospace ? Appearance.font.family.monospace : Appearance.font.family.main
                    elide: Text.ElideRight
                }
            }
            StyledText {
                Layout.fillWidth: true
                visible: root.supportingText.length > 0
                text: root.supportingText
                color: root.supportingColor
                font.pixelSize: Appearance.font.pixelSize.smallie
                elide: Text.ElideRight
            }
            ColumnLayout {
                id: supportingSlot
                Layout.fillWidth: true
                visible: children.length > 0
                spacing: Appearance.spacing.xs
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
