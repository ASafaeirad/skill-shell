import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Io
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

WindowDialog {
    id: root
    property var screen: root.QsWindow.window?.screen
    property var brightnessMonitor: Brightness.getMonitorForScreen(screen)
    backgroundHeight: 700

    WindowDialogTitle {
        text: "Eye protection"
    }

    WindowDialogSectionHeader {
        text: "Night Light"
    }

    WindowDialogSeparator {
        Layout.topMargin: -22
        Layout.leftMargin: 0
        Layout.rightMargin: 0
    }

    Column {
        id: nightLightColumn
        Layout.topMargin: -16
        Layout.fillWidth: true

        ConfigSwitch {
            anchors {
                left: parent.left
                right: parent.right
            }
            iconSize: Appearance.font.pixelSize.larger
            buttonIcon: "check"
            text: Hyprsunset.temperatureActive
                ? (Config.options.light.night.automatic
                    ? `${"Enabled now"} · ${"Automatic"}`
                    : "Enabled now")
                : (Config.options.light.night.automatic
                    ? `${"Disabled now"} · ${"Automatic"}`
                    : "Disabled")
            checked: Hyprsunset.temperatureActive
            onCheckedChanged: {
                Hyprsunset.toggleTemperature(checked)
            }
        }

        ConfigSwitch {
            anchors {
                left: parent.left
                right: parent.right
            }
            iconSize: Appearance.font.pixelSize.larger
            buttonIcon: "night_sight_auto"
            text: "Automatic"
            checked: Config.options.light.night.automatic
            onCheckedChanged: {
                Config.options.light.night.automatic = checked;
            }
        }

        WindowDialogSlider {
            anchors {
                left: parent.left
                right: parent.right
                leftMargin: 4
                rightMargin: 4
            }
            text: "Intensity"
            from: 6500
            to: 1200
            stopIndicatorValues: [5000, to]
            value: Config.options.light.night.colorTemperature
            onMoved: Config.options.light.night.colorTemperature = value
            tooltipContent: `${Math.round(value)}K`
        }
    }

    WindowDialogSectionHeader {
        text: "Anti-flashbang (experimental)"
    }

    WindowDialogSeparator {
        Layout.topMargin: -22
        Layout.leftMargin: 0
        Layout.rightMargin: 0
    }

    Column {
        id: antiFlashbangColumn
        Layout.topMargin: -16
        Layout.fillWidth: true

        ConfigSwitch {
            anchors {
                left: parent.left
                right: parent.right
            }
            iconSize: Appearance.font.pixelSize.larger
            buttonIcon: "filter"
            text: "Content adjustment"
            checked: HyprlandAntiFlashbangShader.enabled
            onCheckedChanged: {
                if (checked) HyprlandAntiFlashbangShader.enable()
                else HyprlandAntiFlashbangShader.disable()
            }
            StyledToolTip {
                text: "<b>Dims screen content</b> as needed.<br><br>Pros: Immediately responsive<br>Cons: Expensive and can hurt color accuracy<br><br><i>Uses a Hyprland screen shader</i>"
            }
        }

        ConfigSwitch {
            anchors {
                left: parent.left
                right: parent.right
            }
            iconSize: Appearance.font.pixelSize.larger
            buttonIcon: "light_mode"
            text: "Brightness adjustment"
            checked: Config.options.light.antiFlashbang.enable
            onCheckedChanged: {
                Config.options.light.antiFlashbang.enable = checked;
            }
            StyledToolTip {
                text: "Adapts the <b>display (physical screen) brightness</b><br><br>Pros: Less expensive, retains colors<br>Cons: Not immediately responsive<br><br><i>Adjusts display brightness after each Hyprland IPC event</i>"
            }
        }
    }

    WindowDialogSectionHeader {
        text: "Brightness"
    }

    WindowDialogSeparator {
        Layout.topMargin: -22
        Layout.leftMargin: 0
        Layout.rightMargin: 0
    }

    Column {
        id: brightnessColumn
        Layout.topMargin: -16
        Layout.fillWidth: true

        WindowDialogSlider {
            anchors {
                left: parent.left
                right: parent.right
                leftMargin: 4
                rightMargin: 4
            }
            value: root.brightnessMonitor.brightness
            onMoved: root.brightnessMonitor.setBrightness(value)
        }
    }

    WindowDialogSectionHeader {
        text: "Gamma"
    }

    WindowDialogSeparator {
        Layout.topMargin: -22
        Layout.leftMargin: 0
        Layout.rightMargin: 0
    }

    Column {
        id: gammaColumn
        Layout.topMargin: -16
        Layout.fillWidth: true
        Layout.fillHeight: true

        WindowDialogSlider {
            anchors {
                left: parent.left
                right: parent.right
                leftMargin: 4
                rightMargin: 4
            }
            from: Hyprsunset.gammaLowerLimit / 100
            value: Hyprsunset.gamma / 100
            onMoved: Hyprsunset.setGamma(value * 100)
            tooltipContent: `${Math.round(value * 100)}%`
        }
    }

    WindowDialogButtonRow {
        Layout.fillWidth: true

        Item {
            Layout.fillWidth: true
        }

        DialogButton {
            buttonText: "Done"
            onClicked: root.dismiss()
        }
    }
}
