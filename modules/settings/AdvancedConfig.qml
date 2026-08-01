import QtQuick
import qs.modules.common
import qs.modules.common.widgets
import qs.services

ContentPage {
    forceWidth: true

    ContentSection {
        icon: "colors"
        title: "Color generation"

        ConfigSwitch {
            buttonIcon: "hardware"
            text: "Shell & utilities"
            configKey: "appearance.wallpaperTheming.enableAppsAndShell"
        }

        ConfigSwitch {
            buttonIcon: "tv_options_input_settings"
            text: "Qt apps"
            configKey: "appearance.wallpaperTheming.enableQtApps"

            StyledToolTip {
                text: "Shell & utilities theming must also be enabled"
            }

        }

        ConfigSwitch {
            buttonIcon: "terminal"
            text: "Terminal"
            configKey: "appearance.wallpaperTheming.enableTerminal"

            StyledToolTip {
                text: "Shell & utilities theming must also be enabled"
            }

        }

        ConfigRow {
            uniform: true

            ConfigSwitch {
                buttonIcon: "dark_mode"
                text: "Force dark mode in terminal"
                configKey: "appearance.wallpaperTheming.terminalGenerationProps.forceDarkMode"

                StyledToolTip {
                    text: "Ignored if terminal theming is not enabled"
                }

            }

        }

        ConfigSpinBox {
            icon: "invert_colors"
            text: "Terminal: Harmony (%)"
            value: Config.options.appearance.wallpaperTheming.terminalGenerationProps.harmony * 100
            from: 0
            to: 100
            stepSize: 10
            onValueChanged: {
                Config.options.appearance.wallpaperTheming.terminalGenerationProps.harmony = value / 100;
            }
        }

        ConfigSpinBox {
            icon: "gradient"
            text: "Terminal: Harmonize threshold"
            configKey: "appearance.wallpaperTheming.terminalGenerationProps.harmonizeThreshold"
            from: 0
            to: 100
            stepSize: 10
        }

        ConfigSpinBox {
            icon: "format_color_text"
            text: "Terminal: Foreground boost (%)"
            value: Config.options.appearance.wallpaperTheming.terminalGenerationProps.termFgBoost * 100
            from: 0
            to: 100
            stepSize: 10
            onValueChanged: {
                Config.options.appearance.wallpaperTheming.terminalGenerationProps.termFgBoost = value / 100;
            }
        }

    }

}
