import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.m3 as M3
import qs.modules.common.functions
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Io
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

M3.Dialog {
    id: root
    property var screen: root.QsWindow.window?.screen
    property var brightnessMonitor: Brightness.getMonitorForScreen(screen)
    backgroundHeight: 700

    M3.DialogTitle {
        text: "Eye protection"
    }

    M3.DialogSectionHeader {
        text: "Night Light"
    }

    M3.Divider {
        Layout.topMargin: -22
        Layout.leftMargin: 0
        Layout.rightMargin: 0
    }

    Column {
        id: nightLightColumn
        Layout.topMargin: -16
        Layout.fillWidth: true

        M3.ListItem {
            compact: true
            anchors {
                left: parent.left
                right: parent.right
            }
            leadingIcon: "check"
            text: Hyprsunset.temperatureActive
                ? (Config.options.light.night.automatic
                    ? `${"Enabled now"} · ${"Automatic"}`
                    : "Enabled now")
                : (Config.options.light.night.automatic
                    ? `${"Disabled now"} · ${"Automatic"}`
                    : "Disabled")
            onClicked: Hyprsunset.toggleTemperature(!Hyprsunset.temperatureActive)

            M3.Switch {
                checked: Hyprsunset.temperatureActive
                onToggled: Hyprsunset.toggleTemperature(checked)
            }
        }

        M3.ListItem {
            compact: true
            anchors {
                left: parent.left
                right: parent.right
            }
            leadingIcon: "night_sight_auto"
            text: "Automatic"
            onClicked: Config.options.light.night.automatic = !Config.options.light.night.automatic

            M3.Switch {
                checked: Config.options.light.night.automatic
                onToggled: Config.options.light.night.automatic = checked
            }
        }

        Column {
            anchors {
                left: parent.left
                right: parent.right
            }
            spacing: -2

            ContentSubsectionLabel {
                text: "Intensity"
                anchors.left: parent.left
                anchors.right: parent.right
            }

            M3.Slider {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: 4
                anchors.rightMargin: 4
                configuration: StyledSlider.Configuration.S
                from: 6500
                to: 1200
                stopIndicatorValues: [5000, to]
                value: Config.options.light.night.colorTemperature
                onMoved: Config.options.light.night.colorTemperature = value
                tooltipContent: `${Math.round(value)}K`
            }
        }
    }

    M3.DialogSectionHeader {
        text: "Brightness"
    }

    M3.Divider {
        Layout.topMargin: -22
        Layout.leftMargin: 0
        Layout.rightMargin: 0
    }

    Column {
        id: brightnessColumn
        Layout.topMargin: -16
        Layout.fillWidth: true

        M3.Slider {
            anchors {
                left: parent.left
                right: parent.right
                leftMargin: 4
                rightMargin: 4
            }
            configuration: StyledSlider.Configuration.S
            value: root.brightnessMonitor.brightness
            onMoved: root.brightnessMonitor.setBrightness(value)
        }
    }

    M3.DialogSectionHeader {
        text: "Gamma"
    }

    M3.Divider {
        Layout.topMargin: -22
        Layout.leftMargin: 0
        Layout.rightMargin: 0
    }

    Column {
        id: gammaColumn
        Layout.topMargin: -16
        Layout.fillWidth: true
        Layout.fillHeight: true

        M3.Slider {
            anchors {
                left: parent.left
                right: parent.right
                leftMargin: 4
                rightMargin: 4
            }
            configuration: StyledSlider.Configuration.S
            from: Hyprsunset.gammaLowerLimit / 100
            value: Hyprsunset.gamma / 100
            onMoved: Hyprsunset.setGamma(value * 100)
            tooltipContent: `${Math.round(value * 100)}%`
        }
    }

    M3.DialogButtonRow {
        Layout.fillWidth: true

        Item {
            Layout.fillWidth: true
        }

        M3.Button {
            variant: "text"
            text: "Done"
            onClicked: root.dismiss()
        }
    }
}
