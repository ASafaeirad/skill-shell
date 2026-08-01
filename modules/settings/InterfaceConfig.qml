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
            checked: Config.options.lock.useHyprlock
            onCheckedChanged: {
                Config.options.lock.useHyprlock = checked;
            }

            StyledToolTip {
                text: "If you want to somehow use fingerprint unlock..."
            }

        }

        ConfigSwitch {
            buttonIcon: "account_circle"
            text: 'Launch on startup'
            checked: Config.options.lock.launchOnStartup
            onCheckedChanged: {
                Config.options.lock.launchOnStartup = checked;
            }
        }

        ContentSubsection {
            title: "Security"

            ConfigSwitch {
                buttonIcon: "settings_power"
                text: 'Require password to power off/restart'
                checked: Config.options.lock.security.requirePasswordToPower
                onCheckedChanged: {
                    Config.options.lock.security.requirePasswordToPower = checked;
                }

                StyledToolTip {
                    text: "Remember that on most devices one can always hold the power button to force shutdown\nThis only makes it a tiny bit harder for accidents to happen"
                }

            }

            ConfigSwitch {
                buttonIcon: "key_vertical"
                text: 'Also unlock keyring'
                checked: Config.options.lock.security.unlockKeyring
                onCheckedChanged: {
                    Config.options.lock.security.unlockKeyring = checked;
                }

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
                checked: Config.options.lock.centerClock
                onCheckedChanged: {
                    Config.options.lock.centerClock = checked;
                }
            }

            ConfigSwitch {
                buttonIcon: "info"
                text: 'Show "Locked" text'
                checked: Config.options.lock.showLockedText
                onCheckedChanged: {
                    Config.options.lock.showLockedText = checked;
                }
            }

            ConfigSwitch {
                buttonIcon: "shapes"
                text: 'Use varying shapes for password characters'
                checked: Config.options.lock.materialShapeChars
                onCheckedChanged: {
                    Config.options.lock.materialShapeChars = checked;
                }
            }

        }

        ContentSubsection {
            title: "Style: Blurred"

            ConfigSwitch {
                buttonIcon: "blur_on"
                text: 'Enable blur'
                checked: Config.options.lock.blur.enable
                onCheckedChanged: {
                    Config.options.lock.blur.enable = checked;
                }
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
            checked: Config.options.notifications.forceMonitor.enable
            onCheckedChanged: {
                Config.options.notifications.forceMonitor.enable = checked;
            }

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
            checked: Config.options.overlay.openingZoomAnimation
            onCheckedChanged: {
                Config.options.overlay.openingZoomAnimation = checked;
            }
        }

        ConfigSwitch {
            buttonIcon: "texture"
            text: "Darken screen"
            checked: Config.options.overlay.darkenScreen
            onCheckedChanged: {
                Config.options.overlay.darkenScreen = checked;
            }
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
                    checked: Config.options.regionSelector.targetRegions.windows
                    onCheckedChanged: {
                        Config.options.regionSelector.targetRegions.windows = checked;
                    }
                }

                ConfigSwitch {
                    buttonIcon: "right_panel_open"
                    text: 'Layers'
                    checked: Config.options.regionSelector.targetRegions.layers
                    onCheckedChanged: {
                        Config.options.regionSelector.targetRegions.layers = checked;
                    }
                }

                ConfigSwitch {
                    buttonIcon: "nearby"
                    text: 'Content'
                    checked: Config.options.regionSelector.targetRegions.content
                    onCheckedChanged: {
                        Config.options.regionSelector.targetRegions.content = checked;
                    }

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
            checked: Config.options.sidebar.keepRightSidebarLoaded
            onCheckedChanged: {
                Config.options.sidebar.keepRightSidebarLoaded = checked;
            }

            StyledToolTip {
                text: "When enabled keeps the content of the right sidebar loaded to reduce the delay when opening,\nat the cost of around 15MB of consistent RAM usage. Delay significance depends on your system's performance.\nUsing a custom kernel like linux-cachyos might help"
            }

        }

        ContentSubsection {
            title: "Quick toggles"

            ConfigSelectionArray {
                Layout.fillWidth: false
                currentValue: Config.options.sidebar.quickToggles.style
                onSelected: (newValue) => {
                    Config.options.sidebar.quickToggles.style = newValue;
                }
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
                value: Config.options.sidebar.quickToggles.android.columns
                from: 1
                to: 8
                stepSize: 1
                onValueChanged: {
                    Config.options.sidebar.quickToggles.android.columns = value;
                }
            }

        }

        ContentSubsection {
            title: "Sliders"

            ConfigSwitch {
                buttonIcon: "check"
                text: "Enable"
                checked: Config.options.sidebar.quickSliders.enable
                onCheckedChanged: {
                    Config.options.sidebar.quickSliders.enable = checked;
                }
            }

            ConfigSwitch {
                buttonIcon: "brightness_6"
                text: "Brightness"
                enabled: Config.options.sidebar.quickSliders.enable
                checked: Config.options.sidebar.quickSliders.showBrightness
                onCheckedChanged: {
                    Config.options.sidebar.quickSliders.showBrightness = checked;
                }
            }

            ConfigSwitch {
                buttonIcon: "volume_up"
                text: "Volume"
                enabled: Config.options.sidebar.quickSliders.enable
                checked: Config.options.sidebar.quickSliders.showVolume
                onCheckedChanged: {
                    Config.options.sidebar.quickSliders.showVolume = checked;
                }
            }

            ConfigSwitch {
                buttonIcon: "mic"
                text: "Microphone"
                enabled: Config.options.sidebar.quickSliders.enable
                checked: Config.options.sidebar.quickSliders.showMic
                onCheckedChanged: {
                    Config.options.sidebar.quickSliders.showMic = checked;
                }
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
                    checked: Config.options.sidebar.cornerOpen.enable
                    onCheckedChanged: {
                        Config.options.sidebar.cornerOpen.enable = checked;
                    }
                }

            }

            ConfigSwitch {
                buttonIcon: "highlight_mouse_cursor"
                text: "Hover to trigger"
                checked: Config.options.sidebar.cornerOpen.clickless
                onCheckedChanged: {
                    Config.options.sidebar.cornerOpen.clickless = checked;
                }

                StyledToolTip {
                    text: "When this is off you'll have to click"
                }

            }

            Row {
                ConfigSwitch {
                    enabled: !Config.options.sidebar.cornerOpen.clickless
                    text: "Force hover open at absolute corner"
                    checked: Config.options.sidebar.cornerOpen.clicklessCornerEnd
                    onCheckedChanged: {
                        Config.options.sidebar.cornerOpen.clicklessCornerEnd = checked;
                    }

                    StyledToolTip {
                        text: "When the previous option is off and this is on,\nyou can still hover the corner's end to open sidebar,\nand the remaining area can be used for volume/brightness scroll"
                    }

                }

                ConfigSpinBox {
                    icon: "arrow_cool_down"
                    text: "with vertical offset"
                    value: Config.options.sidebar.cornerOpen.clicklessCornerVerticalOffset
                    from: 0
                    to: 20
                    stepSize: 1
                    onValueChanged: {
                        Config.options.sidebar.cornerOpen.clicklessCornerVerticalOffset = value;
                    }

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
                    checked: Config.options.sidebar.cornerOpen.bottom
                    onCheckedChanged: {
                        Config.options.sidebar.cornerOpen.bottom = checked;
                    }

                    StyledToolTip {
                        text: "Place the corners to trigger at the bottom"
                    }

                }

                ConfigSwitch {
                    buttonIcon: "unfold_more_double"
                    text: "Value scroll"
                    checked: Config.options.sidebar.cornerOpen.valueScroll
                    onCheckedChanged: {
                        Config.options.sidebar.cornerOpen.valueScroll = checked;
                    }

                    StyledToolTip {
                        text: "Brightness and volume"
                    }

                }

            }

            ConfigSwitch {
                buttonIcon: "visibility"
                text: "Visualize region"
                checked: Config.options.sidebar.cornerOpen.visualize
                onCheckedChanged: {
                    Config.options.sidebar.cornerOpen.visualize = checked;
                }
            }

            ConfigRow {
                ConfigSpinBox {
                    icon: "arrow_range"
                    text: "Region width"
                    value: Config.options.sidebar.cornerOpen.cornerRegionWidth
                    from: 1
                    to: 300
                    stepSize: 1
                    onValueChanged: {
                        Config.options.sidebar.cornerOpen.cornerRegionWidth = value;
                    }
                }

                ConfigSpinBox {
                    icon: "height"
                    text: "Region height"
                    value: Config.options.sidebar.cornerOpen.cornerRegionHeight
                    from: 1
                    to: 300
                    stepSize: 1
                    onValueChanged: {
                        Config.options.sidebar.cornerOpen.cornerRegionHeight = value;
                    }
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
            checked: Config.options.overview.enable
            onCheckedChanged: {
                Config.options.overview.enable = checked;
            }
        }

        ConfigSwitch {
            buttonIcon: "center_focus_strong"
            text: "Center icons"
            checked: Config.options.overview.centerIcons
            onCheckedChanged: {
                Config.options.overview.centerIcons = checked;
            }
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
                value: Config.options.overview.rows
                from: 1
                to: 20
                stepSize: 1
                onValueChanged: {
                    Config.options.overview.rows = value;
                }
            }

            ConfigSpinBox {
                icon: "splitscreen_right"
                text: "Columns"
                value: Config.options.overview.columns
                from: 1
                to: 20
                stepSize: 1
                onValueChanged: {
                    Config.options.overview.columns = value;
                }
            }

        }

        ConfigRow {
            uniform: true

            ConfigSelectionArray {
                currentValue: Config.options.overview.orderRightLeft
                onSelected: (newValue) => {
                    Config.options.overview.orderRightLeft = newValue;
                }
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
                currentValue: Config.options.overview.orderBottomUp
                onSelected: (newValue) => {
                    Config.options.overview.orderBottomUp = newValue;
                }
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
            checked: Config.options.wallpaperSelector.useSystemFileDialog
            onCheckedChanged: {
                Config.options.wallpaperSelector.useSystemFileDialog = checked;
            }
        }

    }

}
