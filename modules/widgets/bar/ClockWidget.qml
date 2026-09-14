import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.services

Item {
    id: root

    property bool borderless: Config.options.bar.borderless
    property bool showDate: Config.options.bar.verbose

    implicitWidth: rowLayout.implicitWidth + Appearance.font.pixelSize.smaller * 2
    implicitHeight: Appearance.sizes.barHeight

    RowLayout {
        id: rowLayout

        anchors.centerIn: parent
        spacing: Appearance.rounding.verysmall

        StyledText {
            visible: root.showDate
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colSubtext
            text: Qt.locale().toString(DateTime.clock.date, "ddd dd/MM")
        }

        Rectangle {
            visible: root.showDate
            Layout.preferredWidth: 1
            Layout.preferredHeight: Appearance.font.pixelSize.normal
            color: Appearance.colors.colOutlineVariant
        }

        StyledText {
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colOnLayer1
            text: DateTime.time
        }
    }

    MouseArea {
        id: mouseArea

        anchors.fill: parent
        hoverEnabled: !Config.options.bar.tooltips.clickToShow

        ClockWidgetPopup {
            hoverTarget: mouseArea
        }
    }
}
