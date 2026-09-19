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
                    currentValue: Config.options.bar.bottom ? 1 : 0
                    onSelected: (newValue) => {
                        Config.options.bar.bottom = (newValue === 1);
                    }
                    options: [{
                        "displayName": "Top",
                        "icon": "arrow_upward",
                        "value": 0
                    }, {
                        "displayName": "Bottom",
                        "icon": "arrow_downward",
                        "value": 1
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
        icon: "cloud"
        title: "Weather"

        ConfigSwitch {
            buttonIcon: "check"
            text: "Enable"
            configKey: "bar.weather.enable"
        }

    }

    ContentSection {
        icon: "data_usage"
        title: "AI usage"

        ConfigSwitch {
            buttonIcon: "check"
            text: "Show Claude and Codex limits"
            configKey: "bar.aiUsage.enable"
        }

        ConfigSwitch {
            buttonIcon: "pause_circle"
            text: "Pause automatic refresh"
            configKey: "bar.aiUsage.paused"
        }

        ConfigSpinBox {
            icon: "schedule"
            text: "Refresh interval in minutes"
            configKey: "bar.aiUsage.refreshIntervalMinutes"
            from: 1
            to: 60
            stepSize: 1
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
