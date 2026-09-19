pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.services
import Quickshell
import QtQuick
import QtQuick.Layouts

MouseArea {
    id: root
    property bool vertical: false
    property bool hovered: false
    implicitWidth: root.vertical ? Appearance.sizes.verticalBarWidth : (rowLayout.implicitWidth + Appearance.font.pixelSize.smaller * 2)
    implicitHeight: root.vertical ? (colLayout.implicitHeight + Appearance.spacing.xs * 2) : Appearance.sizes.barHeight

    acceptedButtons: Qt.LeftButton | Qt.RightButton
    hoverEnabled: !Config.options.bar.tooltips.clickToShow

    onPressed: {
        if (mouse.button === Qt.RightButton) {
            Weather.getData();
            Quickshell.execDetached(["notify-send", 
                "Weather",
                "Refreshing (manually triggered)"
                , "-a", "Shell"
            ])
            mouse.accepted = false
        }
    }

    RowLayout {
        id: rowLayout
        visible: !root.vertical
        anchors.centerIn: parent

        MaterialSymbol {
            fill: 0
            text: Icons.getWeatherIcon(Weather.data.wCode) ?? "cloud"
            iconSize: Appearance.font.pixelSize.large
            color: Appearance.colors.colOnLayer1
            Layout.alignment: Qt.AlignVCenter
        }

        StyledText {
            visible: true
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colOnLayer1
            text: WeatherUtils.formatTemperature(Weather.data)
            Layout.alignment: Qt.AlignVCenter
        }
    }

    ColumnLayout {
        id: colLayout
        visible: root.vertical
        anchors.centerIn: parent
        spacing: 2

        MaterialSymbol {
            fill: 0
            text: Icons.getWeatherIcon(Weather.data.wCode) ?? "cloud"
            iconSize: Appearance.font.pixelSize.large
            color: Appearance.colors.colOnLayer1
            Layout.alignment: Qt.AlignHCenter
        }

        StyledText {
            visible: true
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: Appearance.colors.colOnLayer1
            text: WeatherUtils.formatTemperature(Weather.data)
            Layout.alignment: Qt.AlignHCenter
        }
    }

    WeatherPopup {
        id: weatherPopup
        hoverTarget: root
    }
}
