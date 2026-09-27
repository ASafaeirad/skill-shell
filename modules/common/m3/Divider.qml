import QtQuick
import QtQuick.Layouts
import qs.modules.common

/**
 * Material 3 divider: a thin line grouping content in lists and containers.
 * https://m3.material.io/components/divider
 *
 *   M3.Divider {}                          // full width, in a ColumnLayout
 *   M3.Divider { vertical: true }          // in a RowLayout
 *   M3.Divider { insetStart: Appearance.spacing.lg }
 */
Item {
    id: root

    property bool vertical: false
    property real insetStart: 0
    property real insetEnd: 0
    property color color: Appearance.colors.colOutlineVariant

    implicitWidth: vertical ? Appearance.sizes.m3DividerThickness : insetStart + insetEnd
    implicitHeight: vertical ? insetStart + insetEnd : Appearance.sizes.m3DividerThickness
    Layout.fillWidth: !vertical
    Layout.fillHeight: vertical

    Rectangle {
        color: root.color
        x: root.vertical ? 0 : root.insetStart
        y: root.vertical ? root.insetStart : 0
        width: root.vertical ? root.width : Math.max(0, root.width - root.insetStart - root.insetEnd)
        height: root.vertical ? Math.max(0, root.height - root.insetStart - root.insetEnd) : root.height
    }
}
