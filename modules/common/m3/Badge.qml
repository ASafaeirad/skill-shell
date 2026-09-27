import QtQuick
import qs.modules.common
import qs.modules.common.widgets

/**
 * Material 3 badge: a dot or a short count on an icon or navigation item.
 * https://m3.material.io/components/badges
 *
 *   MaterialSymbol {
 *       text: "mail"
 *       M3.Badge { text: "3"; anchors { right: parent.right; top: parent.top } }
 *   }
 *
 * Empty text draws the small dot; any text draws the large badge.
 * For a labelled status pill ("Connected", "Failed") use StatusBadge instead.
 */
Rectangle {
    id: root

    property string text: ""
    readonly property bool large: text.length > 0

    implicitHeight: large ? Appearance.sizes.m3BadgeLargeSize : Appearance.sizes.m3BadgeSmallSize
    implicitWidth: large ? Math.max(implicitHeight, label.implicitWidth + Appearance.spacing.xs * 2) : implicitHeight
    radius: Appearance.rounding.full
    color: Appearance.colors.colError

    StyledText {
        id: label
        anchors.centerIn: parent
        visible: root.large
        text: root.text
        color: Appearance.colors.colOnError
        font.pixelSize: Appearance.font.pixelSize.smallest
    }
}
