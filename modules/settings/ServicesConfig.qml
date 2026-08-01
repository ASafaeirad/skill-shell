import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.services

ContentPage {
    forceWidth: true

    ContentSection {
        icon: "music_cast"
        title: "Music Recognition"

        ConfigSpinBox {
            icon: "timer_off"
            text: "Total duration timeout (s)"
            value: Config.options.musicRecognition.timeout
            from: 10
            to: 100
            stepSize: 2
            onValueChanged: {
                Config.options.musicRecognition.timeout = value;
            }
        }

        ConfigSpinBox {
            icon: "av_timer"
            text: "Polling interval (s)"
            value: Config.options.musicRecognition.interval
            from: 2
            to: 10
            stepSize: 1
            onValueChanged: {
                Config.options.musicRecognition.interval = value;
            }
        }

    }

    ContentSection {
        icon: "cell_tower"
        title: "Networking"

        MaterialTextArea {
            Layout.fillWidth: true
            placeholderText: "User agent (for services that require it)"
            text: Config.options.networking.userAgent
            wrapMode: TextEdit.Wrap
            onTextChanged: {
                Config.options.networking.userAgent = text;
            }
        }

    }

    ContentSection {
        icon: "memory"
        title: "Resources"

        ConfigSpinBox {
            icon: "av_timer"
            text: "Polling interval (ms)"
            value: Config.options.resources.updateInterval
            from: 100
            to: 10000
            stepSize: 100
            onValueChanged: {
                Config.options.resources.updateInterval = value;
            }
        }

    }

    ContentSection {
        icon: "file_open"
        title: "Save paths"

        MaterialTextArea {
            Layout.fillWidth: true
            placeholderText: "Video Recording Path"
            text: Config.options.screenRecord.savePath
            wrapMode: TextEdit.Wrap
            onTextChanged: {
                Config.options.screenRecord.savePath = text;
            }
        }

        MaterialTextArea {
            Layout.fillWidth: true
            placeholderText: "Screenshot Path (leave empty to just copy)"
            text: Config.options.screenSnip.savePath
            wrapMode: TextEdit.Wrap
            onTextChanged: {
                Config.options.screenSnip.savePath = text;
            }
        }

    }

    ContentSection {
        icon: "search"
        title: "Search"

        ConfigSwitch {
            text: "Use Levenshtein distance-based algorithm instead of fuzzy"
            checked: Config.options.search.sloppy
            onCheckedChanged: {
                Config.options.search.sloppy = checked;
            }

            StyledToolTip {
                text: "Could be better if you make a ton of typos,\nbut results can be weird and might not work with acronyms\n(e.g. \"GIMP\" might not give you the paint program)"
            }

        }

        ContentSubsection {
            title: "Prefixes"

            ConfigRow {
                uniform: true

                MaterialTextArea {
                    Layout.fillWidth: true
                    placeholderText: "Action"
                    text: Config.options.search.prefix.action
                    wrapMode: TextEdit.Wrap
                    onTextChanged: {
                        Config.options.search.prefix.action = text;
                    }
                }

                MaterialTextArea {
                    Layout.fillWidth: true
                    placeholderText: "Clipboard"
                    text: Config.options.search.prefix.clipboard
                    wrapMode: TextEdit.Wrap
                    onTextChanged: {
                        Config.options.search.prefix.clipboard = text;
                    }
                }

                MaterialTextArea {
                    Layout.fillWidth: true
                    placeholderText: "Emojis"
                    text: Config.options.search.prefix.emojis
                    wrapMode: TextEdit.Wrap
                    onTextChanged: {
                        Config.options.search.prefix.emojis = text;
                    }
                }

            }

            ConfigRow {
                uniform: true

                MaterialTextArea {
                    Layout.fillWidth: true
                    placeholderText: "Math"
                    text: Config.options.search.prefix.math
                    wrapMode: TextEdit.Wrap
                    onTextChanged: {
                        Config.options.search.prefix.math = text;
                    }
                }

                MaterialTextArea {
                    Layout.fillWidth: true
                    placeholderText: "Shell command"
                    text: Config.options.search.prefix.shellCommand
                    wrapMode: TextEdit.Wrap
                    onTextChanged: {
                        Config.options.search.prefix.shellCommand = text;
                    }
                }

                MaterialTextArea {
                    Layout.fillWidth: true
                    placeholderText: "Web search"
                    text: Config.options.search.prefix.webSearch
                    wrapMode: TextEdit.Wrap
                    onTextChanged: {
                        Config.options.search.prefix.webSearch = text;
                    }
                }

            }

        }

        ContentSubsection {
            title: "Web search"

            MaterialTextArea {
                Layout.fillWidth: true
                placeholderText: "Base URL"
                text: Config.options.search.engineBaseUrl
                wrapMode: TextEdit.Wrap
                onTextChanged: {
                    Config.options.search.engineBaseUrl = text;
                }
            }

        }

    }

    ContentSection {
        icon: "weather_mix"
        title: "Weather"

        ConfigRow {
            ConfigSwitch {
                buttonIcon: "assistant_navigation"
                text: "Enable GPS based location"
                checked: Config.options.bar.weather.enableGPS
                onCheckedChanged: {
                    Config.options.bar.weather.enableGPS = checked;
                }
            }

            ConfigSwitch {
                buttonIcon: "thermometer"
                text: "Fahrenheit unit"
                checked: Config.options.bar.weather.useUSCS
                onCheckedChanged: {
                    Config.options.bar.weather.useUSCS = checked;
                }

                StyledToolTip {
                    text: "It may take a few seconds to update"
                }

            }

        }

        MaterialTextArea {
            Layout.fillWidth: true
            placeholderText: "City name"
            text: Config.options.bar.weather.city
            wrapMode: TextEdit.Wrap
            onTextChanged: {
                Config.options.bar.weather.city = text;
            }
        }

        ConfigSpinBox {
            icon: "av_timer"
            text: "Polling interval (m)"
            value: Config.options.bar.weather.fetchInterval
            from: 5
            to: 50
            stepSize: 5
            onValueChanged: {
                Config.options.bar.weather.fetchInterval = value;
            }
        }

    }

}
