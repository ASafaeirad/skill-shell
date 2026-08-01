import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.services

ContentPage {
    forceWidth: true

    ContentSection {
        icon: "side_navigation"
        title: "Sidebars"

        ConfigSwitch {
            buttonIcon: "memory"
            text: 'Keep right sidebar loaded'
            configKey: "sidebar.keepRightSidebarLoaded"

            StyledToolTip {
                text: "When enabled keeps the content of the right sidebar loaded to reduce the delay when opening,\nat the cost of around 15MB of consistent RAM usage. Delay significance depends on your system's performance.\nUsing a custom kernel like linux-cachyos might help"
            }

        }

        ContentSubsection {
            title: "Quick toggles"

            ConfigSelectionArray {
                Layout.fillWidth: false
                configKey: "sidebar.quickToggles.style"
                options: [{
                    "displayName": "Classic",
                    "icon": "password_2",
                    "value": "classic"
                }, {
                    "displayName": "Android",
                    "icon": "action_key",
                    "value": "android"
                }]
            }

            ConfigSpinBox {
                enabled: Config.options.sidebar.quickToggles.style === "android"
                icon: "splitscreen_left"
                text: "Columns"
                configKey: "sidebar.quickToggles.android.columns"
                from: 1
                to: 8
                stepSize: 1
            }

        }

        ContentSubsection {
            title: "Sliders"

            ConfigSwitch {
                buttonIcon: "check"
                text: "Enable"
                configKey: "sidebar.quickSliders.enable"
            }

            ConfigSwitch {
                buttonIcon: "brightness_6"
                text: "Brightness"
                enabled: Config.options.sidebar.quickSliders.enable
                configKey: "sidebar.quickSliders.showBrightness"
            }

            ConfigSwitch {
                buttonIcon: "volume_up"
                text: "Volume"
                enabled: Config.options.sidebar.quickSliders.enable
                configKey: "sidebar.quickSliders.showVolume"
            }

            ConfigSwitch {
                buttonIcon: "mic"
                text: "Microphone"
                enabled: Config.options.sidebar.quickSliders.enable
                configKey: "sidebar.quickSliders.showMic"
            }

        }

        ContentSubsection {
            title: "Corner open"
            tooltip: "Allows you to open sidebars by clicking or hovering screen corners regardless of bar position"

            ConfigRow {
                uniform: true

                ConfigSwitch {
                    buttonIcon: "check"
                    text: "Enable"
                    configKey: "sidebar.cornerOpen.enable"
                }

            }

            ConfigSwitch {
                buttonIcon: "highlight_mouse_cursor"
                text: "Hover to trigger"
                configKey: "sidebar.cornerOpen.clickless"

                StyledToolTip {
                    text: "When this is off you'll have to click"
                }

            }

            Row {
                ConfigSwitch {
                    enabled: !Config.options.sidebar.cornerOpen.clickless
                    text: "Force hover open at absolute corner"
                    configKey: "sidebar.cornerOpen.clicklessCornerEnd"

                    StyledToolTip {
                        text: "When the previous option is off and this is on,\nyou can still hover the corner's end to open sidebar,\nand the remaining area can be used for volume/brightness scroll"
                    }

                }

                ConfigSpinBox {
                    icon: "arrow_cool_down"
                    text: "with vertical offset"
                    configKey: "sidebar.cornerOpen.clicklessCornerVerticalOffset"
                    from: 0
                    to: 20
                    stepSize: 1

                    MouseArea {
                        id: mouseArea

                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.NoButton

                        StyledToolTip {
                            extraVisibleCondition: mouseArea.containsMouse
                            text: "Why this is cool:\nFor non-0 values, it won't trigger when you reach the\nscreen corner along the horizontal edge, but it will when\nyou do along the vertical edge"
                        }

                    }

                }

            }

            ConfigRow {
                uniform: true

                ConfigSwitch {
                    buttonIcon: "vertical_align_bottom"
                    text: "Place at bottom"
                    configKey: "sidebar.cornerOpen.bottom"

                    StyledToolTip {
                        text: "Place the corners to trigger at the bottom"
                    }

                }

                ConfigSwitch {
                    buttonIcon: "unfold_more_double"
                    text: "Value scroll"
                    configKey: "sidebar.cornerOpen.valueScroll"

                    StyledToolTip {
                        text: "Brightness and volume"
                    }

                }

            }

            ConfigSwitch {
                buttonIcon: "visibility"
                text: "Visualize region"
                configKey: "sidebar.cornerOpen.visualize"
            }

            ConfigRow {
                ConfigSpinBox {
                    icon: "arrow_range"
                    text: "Region width"
                    configKey: "sidebar.cornerOpen.cornerRegionWidth"
                    from: 1
                    to: 300
                    stepSize: 1
                }

                ConfigSpinBox {
                    icon: "height"
                    text: "Region height"
                    configKey: "sidebar.cornerOpen.cornerRegionHeight"
                    from: 1
                    to: 300
                    stepSize: 1
                }

            }

        }

    }

}
