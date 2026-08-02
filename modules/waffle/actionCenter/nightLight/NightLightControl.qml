import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import qs
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.waffle.actionCenter
import qs.modules.waffle.looks
import qs.services
import qs.services.network

Item {
    id: root

    Component.onCompleted: {
        if (Bluetooth.defaultAdapter.enabled)
            Bluetooth.defaultAdapter.discovering = true;

    }
    Component.onDestruction: {
        Bluetooth.defaultAdapter.discovering = false;
    }

    WPanelPageColumn {
        anchors.fill: parent

        BodyRectangle {
            implicitHeight: 400
            implicitWidth: 50

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 4
                spacing: 4

                HeaderRow {
                    id: headerRow

                    Layout.fillWidth: true
                    title: "Eye protection"
                }

                StyledFlickable {
                    id: flickable

                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    contentHeight: contentLayout.implicitHeight
                    contentWidth: width
                    clip: true
                    bottomMargin: 12

                    NightLightOptions {
                        id: contentLayout

                        width: flickable.width
                    }

                }

            }

        }

        WPanelSeparator {
        }

        FooterRectangle {
        }

    }

    component NightLightOptions: ColumnLayout {
        spacing: 10

        SectionText {
            text: "Night Light"
        }

        ToggleItem {
            name: "Automatic"
            description: Hyprsunset.temperatureActive
                ? "Night Light is enabled now"
                : "Night Light is disabled now"
            iconName: "auto"
            checked: Config.options.light.night.automatic
            onCheckedChanged: {
                Config.options.light.night.automatic = checked;
            }
        }

        ToggleItem {
            name: Hyprsunset.temperatureActive ? "Enabled now" : "Disabled now"
            description: Config.options.light.night.automatic
                ? "Automatic mode is on"
                : "Automatic mode is off"
            iconName: WIcons.nightLightIcon
            checked: Hyprsunset.temperatureActive
            onCheckedChanged: {
                Hyprsunset.toggleTemperature(checked);
            }
        }

        IntensityEntry {
            Layout.fillWidth: true
        }

    }

    component IntensityEntry: RowLayout {
        spacing: 10

        FluentIcon {
            id: iconWidget

            Layout.leftMargin: 12
            Layout.topMargin: 4
            Layout.bottomMargin: 4
            Layout.alignment: Qt.AlignTop
            icon: "temperature"
            implicitSize: 18
        }

        ColumnLayout {
            Layout.fillWidth: true
            // Layout.leftMargin: 40
            Layout.rightMargin: 12
            spacing: 4

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                WText {
                    Layout.fillWidth: true
                    text: "Intensity"
                    font.pixelSize: Looks.font.pixelSize.large
                }

                WText {
                    Layout.fillWidth: true
                    text: "Adjust the color temperature"
                    color: Looks.colors.subfg
                }

            }

            WSlider {
                Layout.fillWidth: true
                from: 6500
                to: 1200
                value: Config.options.light.night.colorTemperature
                onMoved: Config.options.light.night.colorTemperature = value
                tooltipContent: Math.round((value - from) / (to - from) * 100)
            }

        }

    }

}
