import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.services

ContentPage {
    forceWidth: true

    ContentSection {
        icon: "lock"
        title: "Lock screen"

        ConfigSwitch {
            buttonIcon: "water_drop"
            text: 'Use Hyprlock (instead of Quickshell)'
            configKey: "lock.useHyprlock"

            StyledToolTip {
                text: "If you want to somehow use fingerprint unlock..."
            }

        }

        ConfigSwitch {
            buttonIcon: "account_circle"
            text: 'Launch on startup'
            configKey: "lock.launchOnStartup"
        }

        ContentSubsection {
            title: "Security"

            ConfigSwitch {
                buttonIcon: "settings_power"
                text: 'Require password to power off/restart'
                configKey: "lock.security.requirePasswordToPower"

                StyledToolTip {
                    text: "Remember that on most devices one can always hold the power button to force shutdown\nThis only makes it a tiny bit harder for accidents to happen"
                }

            }

            ConfigSwitch {
                buttonIcon: "key_vertical"
                text: 'Also unlock keyring'
                configKey: "lock.security.unlockKeyring"

                StyledToolTip {
                    text: "This is usually safe and needed for your browser and AI sidebar anyway\nMostly useful for those who use lock on startup instead of a display manager that does it (GDM, SDDM, etc.)"
                }

            }

        }

        ContentSubsection {
            title: "Style: general"

            ConfigSwitch {
                buttonIcon: "center_focus_weak"
                text: 'Center clock'
                configKey: "lock.centerClock"
            }

            ConfigSwitch {
                buttonIcon: "info"
                text: 'Show "Locked" text'
                configKey: "lock.showLockedText"
            }

            ConfigSwitch {
                buttonIcon: "shapes"
                text: 'Use varying shapes for password characters'
                configKey: "lock.materialShapeChars"
            }

        }

        ContentSubsection {
            title: "Style: Blurred"

            ConfigSwitch {
                buttonIcon: "blur_on"
                text: 'Enable blur'
                configKey: "lock.blur.enable"
            }

            ConfigSpinBox {
                icon: "loupe"
                text: "Extra wallpaper zoom (%)"
                value: Config.options.lock.blur.extraZoom * 100
                from: 1
                to: 150
                stepSize: 2
                onValueChanged: {
                    Config.options.lock.blur.extraZoom = value / 100;
                }
            }

        }

    }

    ContentSection {
        icon: "notifications"
        title: "Notifications"

        ConfigSwitch {
            buttonIcon: "monitor"
            text: "Force specific monitor"
            configKey: "notifications.forceMonitor.enable"

            StyledToolTip {
                text: "If you have multiple monitors and want notifications to only show on one of them, enable this and enter the monitor name below (e.g., eDP-1)"
            }

        }

        ConfigRow {
            enabled: Config.options.notifications.forceMonitor.enable

            MaterialTextArea {
                Layout.fillWidth: true
                placeholderText: "Monitor name to show notifications on (e.g., eDP-1)"
                text: Config.options.notifications.forceMonitor.name
                wrapMode: TextEdit.Wrap
                onTextChanged: {
                    Config.options.notifications.forceMonitor.name = text;
                }
            }

        }

    }

    ContentSection {
        icon: "select_window"
        title: "Overlay: General"

        ConfigSwitch {
            buttonIcon: "high_density"
            text: "Enable opening zoom animation"
            configKey: "overlay.openingZoomAnimation"
        }

        ConfigSwitch {
            buttonIcon: "texture"
            text: "Darken screen"
            configKey: "overlay.darkenScreen"
        }

    }

    ContentSection {
        icon: "point_scan"
        title: "Overlay: Floating Image"

        MaterialTextArea {
            Layout.fillWidth: true
            placeholderText: "Image source"
            text: Config.options.overlay.floatingImage.imageSource
            wrapMode: TextEdit.Wrap
            onTextChanged: {
                Config.options.overlay.floatingImage.imageSource = text;
            }
        }

    }

    ContentSection {
        icon: "screenshot_frame_2"
        title: "Region selector (screen snipping/Google Lens)"

        ContentSubsection {
            title: "Hint target regions"

            ConfigRow {
                ConfigSwitch {
                    buttonIcon: "select_window"
                    text: 'Windows'
                    configKey: "regionSelector.targetRegions.windows"
                }

                ConfigSwitch {
                    buttonIcon: "right_panel_open"
                    text: 'Layers'
                    configKey: "regionSelector.targetRegions.layers"
                }

                ConfigSwitch {
                    buttonIcon: "nearby"
                    text: 'Content'
                    configKey: "regionSelector.targetRegions.content"

                    StyledToolTip {
                        text: "Could be images or parts of the screen that have some containment.\nMight not always be accurate.\nThis is done with an image processing algorithm run locally and no AI is used."
                    }

                }

            }

        }

        ContentSubsection {
            title: "Google Lens"

            ConfigSelectionArray {
                currentValue: Config.options.search.imageSearch.useCircleSelection ? "circle" : "rectangles"
                onSelected: (newValue) => {
                    Config.options.search.imageSearch.useCircleSelection = (newValue === "circle");
                }
                options: [{
                    "icon": "activity_zone",
                    "value": "rectangles",
                    "displayName": "Rectangular selection"
                }, {
                    "icon": "gesture",
                    "value": "circle",
                    "displayName": "Circle to Search"
                }]
            }

        }

    }

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

    ContentSection {
        icon: "overview_key"
        title: "Overview"

        ConfigSwitch {
            buttonIcon: "check"
            text: "Enable"
            configKey: "overview.enable"
        }

        ConfigSwitch {
            buttonIcon: "center_focus_strong"
            text: "Center icons"
            configKey: "overview.centerIcons"
        }

        ConfigSpinBox {
            icon: "loupe"
            text: "Scale (%)"
            value: Config.options.overview.scale * 100
            from: 1
            to: 100
            stepSize: 1
            onValueChanged: {
                Config.options.overview.scale = value / 100;
            }
        }

        ConfigRow {
            uniform: true

            ConfigSpinBox {
                icon: "splitscreen_bottom"
                text: "Rows"
                configKey: "overview.rows"
                from: 1
                to: 20
                stepSize: 1
            }

            ConfigSpinBox {
                icon: "splitscreen_right"
                text: "Columns"
                configKey: "overview.columns"
                from: 1
                to: 20
                stepSize: 1
            }

        }

        ConfigRow {
            uniform: true

            ConfigSelectionArray {
                configKey: "overview.orderRightLeft"
                options: [{
                    "displayName": "Left to right",
                    "icon": "arrow_forward",
                    "value": 0
                }, {
                    "displayName": "Right to left",
                    "icon": "arrow_back",
                    "value": 1
                }]
            }

            ConfigSelectionArray {
                configKey: "overview.orderBottomUp"
                options: [{
                    "displayName": "Top-down",
                    "icon": "arrow_downward",
                    "value": 0
                }, {
                    "displayName": "Bottom-up",
                    "icon": "arrow_upward",
                    "value": 1
                }]
            }

        }

    }

    ContentSection {
        icon: "wallpaper_slideshow"
        title: "Wallpaper selector"

        ConfigSwitch {
            buttonIcon: "ad"
            text: 'Use system file picker'
            configKey: "wallpaperSelector.useSystemFileDialog"
        }

    }

}
