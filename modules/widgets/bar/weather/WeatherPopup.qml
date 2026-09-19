import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.widgets.bar
import qs.services

StyledPopup {
    id: root

    contentPadding: 0
    shadowMargin: Appearance.sizes.elevationMargin * 2
    shadowBlur: Appearance.sizes.elevationMargin * 1.5
    shadowSpread: 0
    shadowRadius: backgroundRadius + shadowMargin
    shadowColor: ColorUtils.transparentize(Appearance.colors.colShadow, 0.5)
    shadowOffset: Qt.vector2d(0, Appearance.spacing.xxs)
    backgroundRadius: Appearance.rounding.normal + Appearance.rounding.unsharpen
    clipContent: true

    readonly property var forecast: Weather.data?.hourly ?? []

    Column {
        id: card

        anchors.centerIn: parent
        width: Appearance.sizes.notificationPopupWidth
        spacing: 0

        Item {
            width: card.width
            implicitHeight: currentConditions.implicitHeight + Appearance.spacing.xl * 2

            Column { // Current weather conditions
                id: currentConditions

                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: Appearance.spacing.xl
                }
                spacing: Appearance.spacing.s

                Row { // Location row
                    spacing: Appearance.spacing.xxs

                    MaterialSymbol {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "location_on"
                        fill: 0
                        iconSize: Appearance.font.pixelSize.normal
                        color: Appearance.colors.colSubtext
                    }

                    StyledText {
                        text: Weather.data.city
                        color: Appearance.colors.colSubtext
                        font.pixelSize: Appearance.font.pixelSize.small
                    }
                }

                RowLayout {
                    width: parent.width
                    spacing: Appearance.spacing.s

                    Row { // Temperature row
                        Layout.fillWidth: true
                        spacing: Appearance.spacing.xxs

                        StyledText {
                            text: WeatherUtils.formatTempValue(Weather.data)
                            color: Appearance.colors.colOnSurface
                            font {
                                family: Appearance.font.family.expressive
                                features: ({
                                               "tnum": 1
                                           })
                                pixelSize: Appearance.font.pixelSize.huge * 3
                                weight: Font.Normal
                            }
                        }

                        StyledText {
                            anchors.top: parent.top
                            anchors.topMargin: Appearance.spacing.lg
                            text: Weather.data.tempUnit ?? "°C"
                            color: Appearance.colors.colSubtext
                            font {
                                family: Appearance.font.family.expressive
                                features: ({
                                               "tnum": 1
                                           })
                                pixelSize: Appearance.font.pixelSize.smaller
                                weight: Font.Normal
                            }
                        }
                    }

                    MaterialSymbol {
                        Layout.alignment: Qt.AlignVCenter
                        text: Icons.getWeatherIcon(Weather.data.wCode) ?? "cloud"
                        fill: 0
                        iconSize: Appearance.font.pixelSize.huge * 2.5
                        color: Appearance.colors.colPrimary
                    }
                }

                StyledText {
                    text: "%1 · feels like %2".arg(Weather.data.description).arg(WeatherUtils.formatFeelsLike(Weather.data))
                    color: Appearance.colors.colOnSurfaceVariant
                    font.pixelSize: Appearance.font.pixelSize.small
                }

                Row { // Weather metrics row
                    spacing: Appearance.spacing.xs

                    Repeater {
                        model: [
                            {
                                icon: "air",
                                value: WeatherUtils.formatWind(Weather.data)
                            },
                            {
                                icon: "humidity_low",
                                value: WeatherUtils.formatHumidity(Weather.data)
                            },
                            {
                                icon: "light_mode",
                                value: WeatherUtils.formatUV(Weather.data)
                            }
                        ]

                        Rectangle { // Weather metric container
                            required property var modelData

                            implicitWidth: metricRow.implicitWidth + Appearance.spacing.s * 2
                            implicitHeight: metricRow.implicitHeight + Appearance.spacing.xs * 2
                            radius: Appearance.rounding.full
                            color: Appearance.colors.colSurfaceContainerHigh

                            Row {
                                id: metricRow

                                anchors.centerIn: parent
                                spacing: Appearance.spacing.xs

                                MaterialSymbol {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.icon
                                    fill: 0
                                    iconSize: Appearance.font.pixelSize.smaller
                                    color: Appearance.colors.colSubtext
                                }

                                StyledText {
                                    text: modelData.value
                                    color: Appearance.colors.colOnSurfaceVariant
                                    font.pixelSize: Appearance.font.pixelSize.small
                                }
                            }
                        }
                    }
                }
            }
        }

        Rectangle { // Forecast section container
            width: card.width
            implicitHeight: forecastSection.implicitHeight + Appearance.spacing.lg + Appearance.spacing.s
            color: Appearance.colors.colSurfaceContainerHigh
            bottomLeftRadius: root.backgroundRadius
            bottomRightRadius: root.backgroundRadius
            visible: root.forecast.length > 1

            Column { // Forecast section
                id: forecastSection

                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    bottom: parent.bottom
                    leftMargin: Appearance.spacing.xl
                    rightMargin: Appearance.spacing.xl
                    topMargin: Appearance.spacing.m
                }
                spacing: Appearance.spacing.m

                RowLayout { // Forecast section header
                    width: parent.width

                    StyledText {
                        Layout.fillWidth: true
                        text: "Chance of rain"
                        color: Appearance.colors.colSubtext
                        font {
                            pixelSize: Appearance.font.pixelSize.smallest
                            capitalization: Font.AllUppercase
                            letterSpacing: Appearance.spacing.xxs / 2
                        }
                    }
                }

                Item { // Rain labels row
                    id: rainLabels

                    width: parent.width
                    height: Appearance.font.pixelSize.small

                    Repeater {
                        id: rainRepeater
                        model: root.forecast

                        Item {
                            required property var modelData
                            required property int index

                            x: index * rainLabels.width / Math.max(1, rainRepeater.count - 1)
                            width: 0
                            height: rainLabels.height

                            StyledText {
                                id: rainLabel

                                x: index === 0 ? 0 : index === rainRepeater.count - 1 ? -implicitWidth :
                                                                                        -implicitWidth / 2
                                text: `${modelData.chanceOfRain}%`
                                color: modelData.chanceOfRain === rainGraph.peakRain
                                       ? Appearance.colors.colOnSurface : Appearance.colors.colSubtext
                                font.pixelSize: modelData.chanceOfRain === rainGraph.peakRain
                                                ? Appearance.font.pixelSize.small :
                                                  Appearance.font.pixelSize.smallest
                            }
                        }
                    }
                }

                Canvas { // Rain graph
                    id: rainGraph

                    width: parent.width
                    height: Appearance.font.pixelSize.huge * 3
                    readonly property var points: root.forecast
                    readonly property real peakRain: {
                        let peak = 0;
                        for (const point of points)
                            peak = Math.max(peak, point.chanceOfRain);
                        return peak;
                    }

                    onPointsChanged: requestPaint()
                    onWidthChanged: requestPaint()
                    onHeightChanged: requestPaint()

                    onPaint: {
                        const ctx = getContext("2d");
                        ctx.clearRect(0, 0, width, height);
                        if (!points || points.length < 2)
                            return;

                        const inset = 0;
                        const axisLineWidth = Appearance.spacing.xxs / 2;
                        const graphHeight = height - axisLineWidth / 2;
                        const step = (width - inset * 2) / (points.length - 1);
                        const pointX = index => inset + step * index;
                        const pointY = index => graphHeight - (Math.max(0, Math.min(100,
                                                                                    points[index].chanceOfRain))
                                                               / 100) * graphHeight;

                        function curvePath() {
                            ctx.beginPath();
                            ctx.moveTo(pointX(0), pointY(0));
                            for (let index = 1; index < points.length; index++) {
                                const previousX = pointX(index - 1);
                                const previousY = pointY(index - 1);
                                const x = pointX(index);
                                const y = pointY(index);
                                const middleX = (previousX + x) / 2;
                                ctx.bezierCurveTo(middleX, previousY, middleX, y, x, y);
                            }
                        }

                        curvePath();
                        ctx.lineTo(pointX(points.length - 1), graphHeight);
                        ctx.lineTo(pointX(0), graphHeight);
                        ctx.closePath();
                        const gradient = ctx.createLinearGradient(0, 0, 0, height);
                        gradient.addColorStop(0, ColorUtils.transparentize(Appearance.colors.colPrimary,
                                                                           0.72));
                        gradient.addColorStop(1, ColorUtils.transparentize(Appearance.colors.colPrimary, 1));
                        ctx.fillStyle = gradient;
                        ctx.fill();

                        ctx.beginPath();
                        ctx.moveTo(pointX(0), graphHeight);
                        ctx.lineTo(pointX(points.length - 1), graphHeight);
                        ctx.strokeStyle = Appearance.colors.colOutlineVariant;
                        ctx.lineWidth = axisLineWidth;
                        ctx.stroke();

                        curvePath();
                        ctx.strokeStyle = Appearance.colors.colPrimary;
                        ctx.lineWidth = Appearance.spacing.xxs;
                        ctx.stroke();
                    }
                }

                Item {
                    id: forecastLabels

                    width: parent.width
                    height: labelSizer.implicitHeight

                    Repeater {
                        id: forecastRepeater
                        model: root.forecast

                        Item {
                            required property var modelData
                            required property int index

                            x: index * forecastLabels.width / Math.max(1, forecastRepeater.count - 1)
                            width: 0
                            height: forecastLabels.height

                            Column {
                                id: forecastLabel

                                x: index === 0 ? 0 : index === forecastRepeater.count - 1 ? -implicitWidth :
                                                                                            -implicitWidth / 2
                                spacing: Appearance.spacing.xxs

                                StyledText {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: `${modelData.temp}°`
                                    color: Appearance.colors.colOnSurface
                                    font {
                                        features: ({
                                                       "tnum": 1
                                                   })
                                        pixelSize: Appearance.font.pixelSize.small
                                    }
                                }

                                StyledText {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: modelData.time
                                    color: Appearance.colors.colSubtext
                                    font.pixelSize: Appearance.font.pixelSize.smallest
                                }
                            }
                        }
                    }

                    Column {
                        id: labelSizer
                        visible: false
                        StyledText {
                            text: "24°"
                            font.pixelSize: Appearance.font.pixelSize.small
                        }
                        StyledText {
                            text: "now"
                            font.pixelSize: Appearance.font.pixelSize.smallest
                        }
                    }
                }

                RowLayout {
                    width: parent.width

                    Row {
                        Layout.fillWidth: true
                        spacing: Appearance.spacing.xs

                        MaterialSymbol {
                            anchors.baseline: sunTimesText.baseline
                            text: "wb_twilight"
                            fill: 0
                            iconSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colSubtext
                        }

                        StyledText {
                            id: sunTimesText
                            text: WeatherUtils.formatSunTimes(Weather.data)
                            color: Appearance.colors.colSubtext
                            font.pixelSize: Appearance.font.pixelSize.smaller
                        }
                    }

                    StyledText {
                        text: `Updated ${Weather.data.lastRefreshTime}`
                        color: Appearance.colors.colSubtext
                        font.pixelSize: Appearance.font.pixelSize.smaller
                    }
                }
            }
        }
    }
}
