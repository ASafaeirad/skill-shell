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
        icon: "cloud"
        title: "Weather"

        ConfigSwitch {
            buttonIcon: "check"
            text: "Enable"
            configKey: "bar.weather.enable"
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
