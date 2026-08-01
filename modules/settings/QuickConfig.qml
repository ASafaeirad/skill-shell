import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.services

ContentPage {
    forceWidth: true

    // Wallpaper selection
    ContentSection {
        icon: "wallpaper"
        title: "Wallpaper"
        Layout.fillWidth: true

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Item {
                implicitWidth: 340
                implicitHeight: 200

                StyledImage {
                    id: wallpaperPreview

                    anchors.fill: parent
                    fillMode: Image.PreserveAspectCrop
                    source: Config.options.background.wallpaperPath
                    cache: false
                    layer.enabled: true

                    layer.effect: OpacityMask {

                        maskSource: Rectangle {
                            width: 360
                            height: 200
                            radius: Appearance.rounding.normal
                        }

                    }

                }

            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignTop

                RippleButtonWithIcon {
                    Layout.fillWidth: true
                    materialIcon: "wallpaper"
                    onClicked: {
                        Quickshell.execDetached([
                            "qs",
                            "-p",
                            Quickshell.shellPath(""),
                            "ipc",
                            "call",
                            "wallpaperSelector",
                            "toggle"
                        ]);
                    }

                    StyledToolTip {
                        text: "Pick wallpaper image on your system"
                    }

                    mainContentComponent: Component {
                        RowLayout {
                            spacing: 10

                            StyledText {
                                font.pixelSize: Appearance.font.pixelSize.small
                                text: "Choose file"
                                color: Appearance.colors.colOnSecondaryContainer
                            }
                        }

                    }

                }

                ConfigSwitch {
                    buttonIcon: "ad"
                    text: "Use system file picker"
                    configKey: "wallpaperSelector.useSystemFileDialog"
                }

                Item {
                    Layout.fillHeight: true
                }

            }

        }

    }

    ContentSection {
        icon: "format_paint"
        title: "Colors"
        Layout.fillWidth: true

        ContentSubsection {
            title: "Mode"

            ConfigSelectionArray {
                currentValue: Appearance.m3colors.darkmode ? "dark" : "light"
                onSelected: (newValue) => {
                    Quickshell.execDetached(["bash", "-c", `${Directories.wallpaperSwitchScriptPath} --mode ${newValue} --noswitch`]);
                }
                options: [{
                    "value": "light",
                    "icon": "light_mode",
                    "displayName": "Light"
                }, {
                    "value": "dark",
                    "icon": "dark_mode",
                    "displayName": "Dark"
                }]
            }

        }

        ContentSubsection {
            title: "Palette"
            tooltip: "How colors are derived from your wallpaper"

            ConfigSelectionArray {
                currentValue: Config.options.appearance.palette.type
                onSelected: (newValue) => {
                    Config.options.appearance.palette.type = newValue;
                    Quickshell.execDetached(["bash", "-c", `${Directories.wallpaperSwitchScriptPath} --noswitch`]);
                }
                options: [{
                    "value": "auto",
                    "displayName": "Auto"
                }, {
                    "value": "scheme-content",
                    "displayName": "Content"
                }, {
                    "value": "scheme-expressive",
                    "displayName": "Expressive"
                }, {
                    "value": "scheme-fidelity",
                    "displayName": "Fidelity"
                }, {
                    "value": "scheme-fruit-salad",
                    "displayName": "Fruit Salad"
                }, {
                    "value": "scheme-monochrome",
                    "displayName": "Monochrome"
                }, {
                    "value": "scheme-neutral",
                    "displayName": "Neutral"
                }, {
                    "value": "scheme-rainbow",
                    "displayName": "Rainbow"
                }, {
                    "value": "scheme-tonal-spot",
                    "displayName": "Tonal Spot"
                }]
            }

        }

        ContentSubsection {
            title: "Style"

            ConfigSwitch {
                buttonIcon: "ev_shadow"
                text: "Transparency"
                configKey: "appearance.transparency.enable"
            }

        }

    }

    ContentSection {
        icon: "screenshot_monitor"
        title: "Bar & screen"

        ConfigRow {
            ContentSubsection {
                title: "Bar position"

                ConfigSelectionArray {
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
                title: "Bar style"

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

        }

        ConfigRow {
            ContentSubsection {
                title: "Screen round corner"

                ConfigSelectionArray {
                    configKey: "appearance.fakeScreenRounding"
                    options: [{
                        "displayName": "No",
                        "icon": "close",
                        "value": 0
                    }, {
                        "displayName": "Yes",
                        "icon": "check",
                        "value": 1
                    }, {
                        "displayName": "When not fullscreen",
                        "icon": "fullscreen_exit",
                        "value": 2
                    }]
                }

            }

        }

    }

}
