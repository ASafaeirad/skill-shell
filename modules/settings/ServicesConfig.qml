import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.services

ContentPage {
    forceWidth: true

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
            configKey: "search.sloppy"

            StyledToolTip {
                text: "Could be better if you make a ton of typos,\nbut results can be weird and might not work with acronyms\n(e.g. \"GIMP\" might not give you the paint program)"
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
                configKey: "bar.weather.enableGPS"
            }

            ConfigSwitch {
                buttonIcon: "thermometer"
                text: "Fahrenheit unit"
                configKey: "bar.weather.useUSCS"

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
            configKey: "bar.weather.fetchInterval"
            from: 5
            to: 50
            stepSize: 5
        }

    }

}
