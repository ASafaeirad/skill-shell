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
        icon: "format_paint"
        title: "Wallpaper & Colors"
        Layout.fillWidth: true

        RowLayout {
            Layout.fillWidth: true

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

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    uniformCellSizes: true

                    SmallLightDarkPreferenceButton {
                        Layout.fillHeight: true
                        dark: false
                    }

                    SmallLightDarkPreferenceButton {
                        Layout.fillHeight: true
                        dark: true
                    }

                }

            }

        }

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

        ConfigSwitch {
            buttonIcon: "ev_shadow"
            text: "Transparency"
            configKey: "appearance.transparency.enable"
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

    component SmallLightDarkPreferenceButton: RippleButton {
        id: smallLightDarkPreferenceButton

        required property bool dark
        property color colText: toggled ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer2

        padding: 5
        Layout.fillWidth: true
        toggled: Appearance.m3colors.darkmode === dark
        colBackground: Appearance.colors.colLayer2
        onClicked: {
            Quickshell.execDetached(["bash", "-c", `${Directories.wallpaperSwitchScriptPath} --mode ${dark ? "dark" : "light"} --noswitch`]);
        }

        contentItem: Item {
            anchors.centerIn: parent

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 0

                MaterialSymbol {
                    Layout.alignment: Qt.AlignHCenter
                    iconSize: 30
                    text: dark ? "dark_mode" : "light_mode"
                    color: smallLightDarkPreferenceButton.colText
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: dark ? "Dark" : "Light"
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: smallLightDarkPreferenceButton.colText
                }

            }

        }

    }

}
