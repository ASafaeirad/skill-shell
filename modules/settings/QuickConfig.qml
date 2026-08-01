import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.services

ContentPage {
    forceWidth: true

    Process {
        id: randomWallProc

        property string status: ""
        property string scriptPath: `${Directories.scriptPath}/colors/random/random_konachan_wall.sh`

        command: ["bash", "-c", FileUtils.trimFileProtocol(randomWallProc.scriptPath)]

        stdout: SplitParser {
            onRead: (data) => {
                randomWallProc.status = data.trim();
            }
        }

    }

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
                    enabled: !randomWallProc.running
                    visible: Config.options.policies.weeb === 1
                    Layout.fillWidth: true
                    buttonRadius: Appearance.rounding.small
                    materialIcon: "ifl"
                    mainText: randomWallProc.running ? "Be patient..." : "Random: Konachan"
                    onClicked: {
                        randomWallProc.scriptPath = `${Directories.scriptPath}/colors/random/random_konachan_wall.sh`;
                        randomWallProc.running = true;
                    }

                    StyledToolTip {
                        text: "Random SFW Anime wallpaper from Konachan\nImage is saved to ~/Pictures/Wallpapers"
                    }

                }

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

                            RowLayout {
                                spacing: 3

                                KeyboardKey {
                                    key: "Ctrl"
                                }

                                KeyboardKey {
                                    key: Config.options.cheatsheet.superKey ?? "󰖳"
                                }

                                StyledText {
                                    Layout.alignment: Qt.AlignVCenter
                                    text: "+"
                                }

                                KeyboardKey {
                                    key: "T"
                                }

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
            checked: Config.options.appearance.transparency.enable
            onCheckedChanged: {
                Config.options.appearance.transparency.enable = checked;
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
                title: "Bar style"

                ConfigSelectionArray {
                    currentValue: Config.options.bar.cornerStyle
                    onSelected: (newValue) => {
                        Config.options.bar.cornerStyle = newValue; // Update local copy
                    }
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
                    currentValue: Config.options.appearance.fakeScreenRounding
                    onSelected: (newValue) => {
                        Config.options.appearance.fakeScreenRounding = newValue;
                    }
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

    NoticeBox {
        Layout.fillWidth: true
        text: 'Not all options are available in this app. You should also check the config file by hitting the "Config file" button on the topleft corner or opening %1 manually.'.arg(Directories.shellConfigPath)

        Item {
            Layout.fillWidth: true
        }

        RippleButtonWithIcon {
            id: copyPathButton

            property bool justCopied: false

            Layout.fillWidth: false
            buttonRadius: Appearance.rounding.small
            materialIcon: justCopied ? "check" : "content_copy"
            mainText: justCopied ? "Path copied" : "Copy path"
            onClicked: {
                copyPathButton.justCopied = true;
                Quickshell.clipboardText = FileUtils.trimFileProtocol(`${Directories.config}/skill-shell/config.json`);
                revertTextTimer.restart();
            }
            colBackground: ColorUtils.transparentize(Appearance.colors.colPrimaryContainer)
            colBackgroundHover: Appearance.colors.colPrimaryContainerHover
            colRipple: Appearance.colors.colPrimaryContainerActive

            Timer {
                id: revertTextTimer

                interval: 1500
                onTriggered: {
                    copyPathButton.justCopied = false;
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
