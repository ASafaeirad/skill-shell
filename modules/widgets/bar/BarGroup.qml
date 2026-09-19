import qs.modules.common
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    property real padding: 5
    implicitWidth: gridLayout.implicitWidth + padding * 2
    implicitHeight: Appearance.sizes.baseBarHeight
    default property alias items: gridLayout.children

    Rectangle {
        id: background
        anchors {
            fill: parent
            topMargin: Appearance.spacing.s
            bottomMargin: Appearance.spacing.s
        }
        color: Config.options?.bar.borderless ? "transparent" : Appearance.colors.colLayer1
        radius: Appearance.rounding.small
    }

    GridLayout {
        id: gridLayout
        columns: -1
        rows: 1
        anchors {
            verticalCenter: parent.verticalCenter
            left: parent.left
            right: parent.right
            margins: root.padding
        }
        columnSpacing: 4
        rowSpacing: 12
    }
}
