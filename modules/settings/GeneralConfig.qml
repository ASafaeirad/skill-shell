import QtQuick
import Quickshell
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

ContentPage {
    forceWidth: true

    ContentSection {
        icon: "battery_android_full"
        title: "Battery"

        ConfigRow {
            uniform: true
            ConfigSpinBox {
                icon: "warning"
                text: "Low warning"
                configKey: "battery.low"
                from: 0
                to: 100
                stepSize: 5
            }
            ConfigSpinBox {
                icon: "dangerous"
                text: "Critical warning"
                configKey: "battery.critical"
                from: 0
                to: 100
                stepSize: 5
            }
        }
        ConfigRow {
            uniform: false
            Layout.fillWidth: false
            ConfigSwitch {
                buttonIcon: "pause"
                text: "Automatic suspend"
                configKey: "battery.automaticSuspend"
                StyledToolTip {
                    text: "Automatically suspends the system when battery is low"
                }
            }
            ConfigSpinBox {
                enabled: Config.options.battery.automaticSuspend
                text: "at"
                configKey: "battery.suspend"
                from: 0
                to: 100
                stepSize: 5
            }
        }
        ConfigRow {
            uniform: true
            ConfigSpinBox {
                icon: "charger"
                text: "Full warning"
                configKey: "battery.full"
                from: 0
                to: 101
                stepSize: 5
            }
        }
    }

    ContentSection {
        icon: "bolt"
        title: "Power mode"

        ConfigSwitch {
            buttonIcon: "settings_power"
            text: "Manage power profile"
            configKey: "battery.autoPowerProfile"
            StyledToolTip {
                text: "Lets the shell set the power profile and refresh rate. Off means nothing is applied automatically and the mode below is ignored."
            }
        }

        ConfigSelectionArray {
            enabled: Config.options.battery.autoPowerProfile
            configKey: "battery.powerMode"
            options: [
                {
                    "displayName": "Auto",
                    "icon": "autorenew",
                    "value": "auto"
                },
                {
                    "displayName": "Performance",
                    "icon": "local_fire_department",
                    "value": "performance"
                },
                {
                    "displayName": "Power Saver",
                    "icon": "energy_savings_leaf",
                    "value": "powersaver"
                }
            ]
            StyledToolTip {
                text: "Auto follows the power source: balanced and 240Hz on AC, power saver and 60Hz on battery. Performance pins the performance profile and 240Hz on both sources. Power Saver pins the power saver profile on both, while refresh rate still follows the source. Plugged in is always 240Hz."
            }
        }
    }

    ContentSection {
        icon: "notification_sound"
        title: "Sounds"
        ConfigRow {
            uniform: true
            ConfigSwitch {
                buttonIcon: "battery_android_full"
                text: "Battery"
                configKey: "sounds.battery"
            }
            ConfigSwitch {
                buttonIcon: "av_timer"
                text: "Pomodoro"
                configKey: "sounds.pomodoro"
            }
        }
    }

    ContentSection {
        icon: "nest_clock_farsight_analog"
        title: "Time"

        ConfigSwitch {
            buttonIcon: "pace"
            text: "Second precision"
            configKey: "time.secondPrecision"
            StyledToolTip {
                text: "Enable if you want clocks to show seconds accurately"
            }
        }

        ContentSubsection {
            title: "Format"
            tooltip: ""

            ConfigSelectionArray {
                currentValue: Config.options.time.format
                onSelected: newValue => {
                    if (newValue === "hh:mm") {
                        Quickshell.execDetached(["bash", "-c", `sed -i 's/\\TIME12\\b/TIME/' '${FileUtils.trimFileProtocol(Directories.config)}/hypr/hyprlock.conf'`]);
                    } else {
                        Quickshell.execDetached(["bash", "-c", `sed -i 's/\\TIME\\b/TIME12/' '${FileUtils.trimFileProtocol(Directories.config)}/hypr/hyprlock.conf'`]);
                    }

                    Config.options.time.format = newValue;
                }
                options: [
                    {
                        displayName: "24h",
                        value: "hh:mm"
                    },
                    {
                        displayName: "12h am/pm",
                        value: "h:mm ap"
                    },
                    {
                        displayName: "12h AM/PM",
                        value: "h:mm AP"
                    },
                ]
            }
        }
    }

}
