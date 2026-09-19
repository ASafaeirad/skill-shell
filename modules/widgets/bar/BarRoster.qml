pragma Singleton

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.widgets.bar as Bar
import qs.modules.widgets.verticalBar as VBar
import qs.modules.widgets.bar.weather as BarWeather

QtObject {
    id: root

    // Component declarations for horizontal and vertical orientations
    property Component activeWindowHorizontal: Component {
        Bar.ActiveWindow {
            Layout.leftMargin: 10 + Appearance.rounding.screenRounding
            Layout.rightMargin: Appearance.rounding.screenRounding
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }

    property Component activeWindowVertical: Component {
        Bar.ActiveWindow {
            vertical: true
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: Appearance.rounding.screenRounding
        }
    }

    property Component workspacesHorizontal: Component {
        Bar.BarGroup {
            padding: workspacesWidget.widgetPadding

            Bar.Workspaces {
                id: workspacesWidget
                Layout.fillHeight: true

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.RightButton
                    onPressed: event => {
                        if (event.button === Qt.RightButton) {
                            GlobalStates.overviewOpen = !GlobalStates.overviewOpen;
                        }
                    }
                }
            }
        }
    }

    property Component workspacesVertical: Component {
        Bar.BarGroup {
            vertical: true
            padding: 6

            Bar.Workspaces {
                id: workspacesWidget
                vertical: true

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.RightButton
                    onPressed: event => {
                        if (event.button === Qt.RightButton) {
                            GlobalStates.overviewOpen = !GlobalStates.overviewOpen;
                        }
                    }
                }
            }
        }
    }

    property Component mediaHorizontal: Component {
        Bar.BarGroup {
            Layout.alignment: Qt.AlignVCenter

            Bar.Media {
                Layout.preferredWidth: Math.min(implicitWidth, Appearance.sizes.barCenterSideModuleWidth)
            }
        }
    }

    property Component mediaVertical: Component {
        Bar.BarGroup {
            vertical: true
            padding: 8

            VBar.VerticalMedia {
                Layout.fillWidth: true
                Layout.fillHeight: false
            }
        }
    }

    property Component weatherHorizontal: Component {
        Bar.BarGroup {
            Layout.leftMargin: 4
            BarWeather.WeatherBar {}
        }
    }

    property Component weatherVertical: Component {
        Bar.BarGroup {
            vertical: true
            padding: 4
            BarWeather.WeatherBar {
                vertical: true
            }
        }
    }

    property Component aiUsageHorizontal: Component {
        Bar.BarGroup {
            Bar.AiUsageWidget {}
        }
    }

    property Component aiUsageVertical: Component {
        Bar.BarGroup {
            vertical: true
            padding: 4
            Bar.AiUsageWidget {
                vertical: true
            }
        }
    }

    property Component clockHorizontal: Component {
        Bar.BarGroup {
            Layout.alignment: Qt.AlignVCenter

            Bar.ClockWidget {
                showDate: Config.options.bar.verbose
            }
        }
    }

    property Component clockVertical: Component {
        Bar.BarGroup {
            vertical: true
            padding: 8

            VBar.VerticalClockWidget {
                Layout.fillWidth: true
                Layout.fillHeight: false
            }
        }
    }

    property Component sysTrayHorizontal: Component {
        Bar.SysTray {
            Layout.fillWidth: false
            Layout.fillHeight: true
            invertSide: Config?.options.bar.bottom
        }
    }

    property Component sysTrayVertical: Component {
        Bar.SysTray {
            vertical: true
            Layout.fillWidth: true
            Layout.fillHeight: false
            invertSide: Config?.options.bar.bottom
        }
    }

    property Component statusIndicatorsHorizontal: Component {
        Bar.StatusIndicators {}
    }

    property Component statusIndicatorsVertical: Component {
        Bar.StatusIndicators {
            vertical: true
        }
    }

    // The unified widget roster
    property var widgets: [
        {
            id: "activeWindow",
            section: "start",
            maxShortenForm: 0,
            horizontalComponent: activeWindowHorizontal,
            verticalComponent: activeWindowVertical
        },
        {
            id: "workspaces",
            section: "center",
            horizontalComponent: workspacesHorizontal,
            verticalComponent: workspacesVertical
        },
        {
            id: "media",
            section: "end",
            maxShortenForm: 1,
            horizontalComponent: mediaHorizontal,
            verticalComponent: mediaVertical
        },
        {
            id: "weather",
            section: "end",
            enabled: () => (Config.options?.bar?.weather?.enable ?? false),
            horizontalComponent: weatherHorizontal,
            verticalComponent: weatherVertical
        },
        {
            id: "aiUsage",
            section: "end",
            maxShortenForm: 0,
            enabled: () => (Config.options?.bar?.aiUsage?.enable ?? false),
            horizontalComponent: aiUsageHorizontal,
            verticalComponent: aiUsageVertical
        },
        {
            id: "clock",
            section: "end",
            horizontalComponent: clockHorizontal,
            verticalComponent: clockVertical
        },
        {
            id: "sysTray",
            section: "end",
            maxShortenForm: 0,
            horizontalComponent: sysTrayHorizontal,
            verticalComponent: sysTrayVertical
        },
        {
            id: "statusIndicators",
            section: "end",
            horizontalComponent: statusIndicatorsHorizontal,
            verticalComponent: statusIndicatorsVertical
        }
    ]

    function widgetsForSection(section) {
        return widgets.filter(w => w.section === section);
    }

    function isWidgetVisible(widget, isVertical, useShortenedForm) {
        let enabled = true;
        if (typeof widget.enabled === "function")
            enabled = widget.enabled();
        else if (widget.enabled !== undefined)
            enabled = widget.enabled;
        if (!enabled)
            return false;

        if (!isVertical) {
            const maxShorten = widget.maxShortenForm ?? 2;
            if (useShortenedForm > maxShorten)
                return false;
        }

        return true;
    }
}
