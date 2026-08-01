import QtQuick
import qs.modules.common
import qs.modules.common.widgets
import qs.services

ContentPage {
    forceWidth: true

    ContentSection {
        icon: "sync_alt"
        title: "Parallax"

        ConfigSwitch {
            buttonIcon: "unfold_more_double"
            text: "Vertical"
            checked: Config.options.background.parallax.vertical
            onCheckedChanged: {
                Config.options.background.parallax.vertical = checked;
            }
        }

        ConfigRow {
            uniform: true

            ConfigSwitch {
                buttonIcon: "counter_1"
                text: "Depends on workspace"
                checked: Config.options.background.parallax.enableWorkspace
                onCheckedChanged: {
                    Config.options.background.parallax.enableWorkspace = checked;
                }
            }

            ConfigSwitch {
                buttonIcon: "side_navigation"
                text: "Depends on sidebars"
                checked: Config.options.background.parallax.enableSidebar
                onCheckedChanged: {
                    Config.options.background.parallax.enableSidebar = checked;
                }
            }
        }

        ConfigSpinBox {
            icon: "loupe"
            text: "Preferred wallpaper zoom (%)"
            value: Config.options.background.parallax.workspaceZoom * 100
            from: 10
            to: 200
            stepSize: 1
            onValueChanged: {
                Config.options.background.parallax.workspaceZoom = value / 100;
            }
        }
    }
}
