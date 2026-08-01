import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.services

ContentPage {
    forceWidth: true

    ContentSection {
        icon: "notifications"
        title: "Notifications"

        ConfigSwitch {
            buttonIcon: "counter_2"
            text: "Unread indicator: show count"
            configKey: "bar.indicators.notifications.showUnreadCount"
        }

    }

    ContentSection {
        icon: "spoke"
        title: "Positioning"

        ConfigRow {
            ContentSubsection {
                title: "Bar position"
                Layout.fillWidth: true

                ConfigSelectionArray {
                    // bottom: false, vertical: false
                    // bottom: false, vertical: true
                    // bottom: true, vertical: false
                    // bottom: true, vertical: true

                    currentValue: (Config.options.bar.bottom ? 1 : 0) | (Config.options.bar.vertical ? 2 : 0)
                    onSelected: (newValue) => {
                        Config.options.bar.bottom = (newValue & 1) !== 0;
                        Config.options.bar.vertical = (newValue & 2) !== 0;
                    }
                    options: [{
                        "displayName": "Top",
                        "icon": "arrow_upward",
                        "value": 0
                    }, {
                        "displayName": "Left",
                        "icon": "arrow_back",
                        "value": 2
                    }, {
                        "displayName": "Bottom",
                        "icon": "arrow_downward",
                        "value": 1
                    }, {
                        "displayName": "Right",
                        "icon": "arrow_forward",
                        "value": 3
                    }]
                }

            }

            ContentSubsection {
                title: "Automatically hide"
                Layout.fillWidth: false

                ConfigSelectionArray {
                    configKey: "bar.autoHide.enable"
                    options: [{
                        "displayName": "No",
                        "icon": "close",
                        "value": false
                    }, {
                        "displayName": "Yes",
                        "icon": "check",
                        "value": true
                    }]
                }

            }

        }

        ConfigRow {
            ContentSubsection {
                title: "Corner style"
                Layout.fillWidth: true

                ConfigSelectionArray {
                    configKey: "bar.cornerStyle"
                    options: [{
                        "displayName": "Hug",
                        "icon": "line_curve",
                        "value": 0
                    }, {
                        "displayName": "Float",
                        "icon": "page_header",
                        "value": 1
                    }, {
                        "displayName": "Rect",
                        "icon": "toolbar",
                        "value": 2
                    }]
                }

            }

            ContentSubsection {
                title: "Group style"
                Layout.fillWidth: false

                ConfigSelectionArray {
                    configKey: "bar.borderless"
                    options: [{
                        "displayName": "Pills",
                        "icon": "location_chip",
                        "value": false
                    }, {
                        "displayName": "Line-separated",
                        "icon": "split_scene",
                        "value": true
                    }]
                }

            }

        }

    }

    ContentSection {
        icon: "shelf_auto_hide"
        title: "Tray"

        ConfigSwitch {
            buttonIcon: "keep"
            text: 'Make icons pinned by default'
            configKey: "tray.invertPinnedItems"
        }

        ConfigSwitch {
            buttonIcon: "colors"
            text: 'Tint icons'
            configKey: "tray.monochromeIcons"
        }

    }

    ContentSection {
        icon: "widgets"
        title: "Utility buttons"

        ConfigRow {
            uniform: true

            ConfigSwitch {
                buttonIcon: "content_cut"
                text: "Screen snip"
                configKey: "bar.utilButtons.showScreenSnip"
            }

            ConfigSwitch {
                buttonIcon: "colorize"
                text: "Color picker"
                configKey: "bar.utilButtons.showColorPicker"
            }

        }

        ConfigRow {
            uniform: true

            ConfigSwitch {
                buttonIcon: "mic"
                text: "Mic toggle"
                configKey: "bar.utilButtons.showMicToggle"
            }

        }

        ConfigRow {
            uniform: true

            ConfigSwitch {
                buttonIcon: "dark_mode"
                text: "Dark/Light toggle"
                configKey: "bar.utilButtons.showDarkModeToggle"
            }

            ConfigSwitch {
                buttonIcon: "speed"
                text: "Performance Profile toggle"
                configKey: "bar.utilButtons.showPerformanceProfileToggle"
            }

        }

        ConfigRow {
            uniform: true

            ConfigSwitch {
                buttonIcon: "videocam"
                text: "Record"
                configKey: "bar.utilButtons.showScreenRecord"
            }

        }

    }

    ContentSection {
        icon: "cloud"
        title: "Weather"

        ConfigSwitch {
            buttonIcon: "check"
            text: "Enable"
            configKey: "bar.weather.enable"
        }

    }

    ContentSection {
        icon: "workspaces"
        title: "Workspaces"

        ConfigSwitch {
            buttonIcon: "counter_1"
            text: 'Always show numbers'
            configKey: "bar.workspaces.alwaysShowNumbers"
        }

        ConfigSwitch {
            buttonIcon: "award_star"
            text: 'Show app icons'
            configKey: "bar.workspaces.showAppIcons"
        }

        ConfigSwitch {
            buttonIcon: "colors"
            text: 'Tint app icons'
            configKey: "bar.workspaces.monochromeIcons"
        }

        ConfigSpinBox {
            icon: "view_column"
            text: "Workspaces shown"
            configKey: "bar.workspaces.shown"
            from: 1
            to: 30
            stepSize: 1
        }

        ConfigSpinBox {
            icon: "touch_long"
            text: "Number show delay when pressing Super (ms)"
            configKey: "bar.workspaces.showNumberDelay"
            from: 0
            to: 1000
            stepSize: 50
        }

        ContentSubsection {
            title: "Number style"

            ConfigSelectionArray {
                currentValue: JSON.stringify(Config.options.bar.workspaces.numberMap)
                onSelected: (newValue) => {
                    Config.options.bar.workspaces.numberMap = JSON.parse(newValue);
                }
                options: [{
                    "displayName": "Normal",
                    "icon": "timer_10",
                    "value": '[]'
                }, {
                    "displayName": "Han chars",
                    "icon": "square_dot",
                    "value": '["一","二","三","四","五","六","七","八","九","十","十一","十二","十三","十四","十五","十六","十七","十八","十九","二十"]'
                }, {
                    "displayName": "Roman",
                    "icon": "account_balance",
                    "value": '["I","II","III","IV","V","VI","VII","VIII","IX","X","XI","XII","XIII","XIV","XV","XVI","XVII","XVIII","XIX","XX"]'
                }]
            }

        }

    }

    ContentSection {
        icon: "tooltip"
        title: "Tooltips"

        ConfigSwitch {
            buttonIcon: "ads_click"
            text: "Click to show"
            configKey: "bar.tooltips.clickToShow"
        }

    }

}
