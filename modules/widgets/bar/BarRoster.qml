pragma Singleton

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.widgets.bar as Bar
import qs.modules.widgets.bar.weather as BarWeather

QtObject {
    id: root

    property Component activeWindow: Component {
        Bar.ActiveWindow {
            Layout.leftMargin: 10 + Appearance.rounding.screenRounding
            Layout.rightMargin: Appearance.rounding.screenRounding
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }

    property Component workspaces: Component {
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

    property Component media: Component {
        Bar.BarGroup {
            Layout.alignment: Qt.AlignVCenter

            Bar.Media {
                Layout.preferredWidth: Math.min(implicitWidth, Appearance.sizes.barCenterSideModuleWidth)
            }
        }
    }

    property Component weather: Component {
        Bar.BarGroup {
            Layout.leftMargin: 4
            BarWeather.WeatherBar {}
        }
    }

    property Component aiUsage: Component {
        Bar.BarGroup {
            Bar.AiUsageWidget {}
        }
    }

    property Component clock: Component {
        Bar.BarGroup {
            Layout.alignment: Qt.AlignVCenter

            Bar.ClockWidget {
                showDate: Config.options.bar.verbose
            }
        }
    }

    property Component sysTray: Component {
        Bar.SysTray {
            Layout.fillWidth: false
            Layout.fillHeight: true
            invertSide: Config?.options.bar.bottom
        }
    }

    property Component statusIndicators: Component {
        Bar.StatusIndicators {}
    }

    // The unified widget roster
    property var widgets: [
        {
            id: "activeWindow",
            section: "start",
            maxShortenForm: 0,
            component: activeWindow
        },
        {
            id: "workspaces",
            section: "center",
            component: workspaces
        },
        {
            id: "media",
            section: "end",
            maxShortenForm: 1,
            component: media
        },
        {
            id: "weather",
            section: "end",
            enabled: () => (Config.options?.bar?.weather?.enable ?? false),
            component: weather
        },
        {
            id: "aiUsage",
            section: "end",
            maxShortenForm: 0,
            enabled: () => (Config.options?.bar?.aiUsage?.enable ?? false),
            component: aiUsage
        },
        {
            id: "clock",
            section: "end",
            component: clock
        },
        {
            id: "sysTray",
            section: "end",
            maxShortenForm: 0,
            component: sysTray
        },
        {
            id: "statusIndicators",
            section: "end",
            component: statusIndicators
        }
    ]

    function widgetsForSection(section) {
        return widgets.filter(w => w.section === section);
    }

    function isWidgetVisible(widget, useShortenedForm) {
        let enabled = true;
        if (typeof widget.enabled === "function")
            enabled = widget.enabled();
        else if (widget.enabled !== undefined)
            enabled = widget.enabled;
        if (!enabled)
            return false;

        const maxShorten = widget.maxShortenForm ?? 2;
        if (useShortenedForm > maxShorten)
            return false;

        return true;
    }
}
