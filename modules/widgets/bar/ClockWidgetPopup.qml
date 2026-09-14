import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.services

StyledPopup {
    id: root

    contentPadding: 0
    backgroundRadius: Appearance.rounding.normal + Appearance.rounding.unsharpen

    readonly property var displayLocale: Qt.locale("en_US")
    readonly property string formattedDay: DateTime.clock.date.getDate().toString()
    readonly property string formattedWeekday: displayLocale.toString(DateTime.clock.date, "dddd")
    readonly property string formattedMonthAndWeek: "%1 · week %2".arg(displayLocale.toString(
                                                                           DateTime.clock.date,
                                                                           "MMMM yyyy")).arg(getIsoWeekNumber(
                                                                                                 DateTime.clock.date))
    readonly property string formattedUptime: DateTime.uptime.split(", ").join(" ")

    function getIsoWeekNumber(date) {
        const target = new Date(Date.UTC(date.getFullYear(), date.getMonth(), date.getDate()));
        const day = target.getUTCDay() || 7;
        target.setUTCDate(target.getUTCDate() + 4 - day);
        const yearStart = new Date(Date.UTC(target.getUTCFullYear(), 0, 1));
        return Math.ceil((((target - yearStart) / 86400000) + 1) / 7);
    }

    Column {
        id: card
        anchors.centerIn: parent
        width: Appearance.sizes.notificationPopupWidth + Appearance.spacing.lg
        spacing: 0

        Item {
            id: dateSection

            width: card.width
            implicitHeight: Appearance.font.pixelSize.huge * 4 + Appearance.spacing.s

            RowLayout {
                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                    leftMargin: Appearance.spacing.xl
                    rightMargin: Appearance.spacing.xl
                }

                StyledText {
                    Layout.alignment: Qt.AlignVCenter
                    text: root.formattedDay
                    color: Appearance.colors.colPrimary
                    Layout.rightMargin: Appearance.spacing.m
                    font {
                        family: Appearance.font.family.expressive
                        features: ({ "tnum": 1 })
                        pixelSize: Appearance.font.pixelSize.huge * 3
                        weight: Font.Normal
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 0

                    StyledText {
                        text: root.formattedWeekday
                        color: Appearance.colors.colOnSurface
                        font.pixelSize: Appearance.font.pixelSize.huge
                    }

                    StyledText {
                        text: root.formattedMonthAndWeek
                        color: Appearance.colors.colSubtext
                        font {
                            features: ({ "tnum": 1 })
                            pixelSize: Appearance.font.pixelSize.expressive
                        }
                    }
                }
            }
        }

        Rectangle {
            width: card.width
            height: Appearance.spacing.xxs / 2
            color: Appearance.colors.colOutlineVariant
        }

        Rectangle {
            width: card.width
            implicitHeight: Appearance.font.pixelSize.huge * 2 + Appearance.spacing.m
            color: Appearance.colors.colSurfaceContainerHigh
            bottomLeftRadius: root.backgroundRadius
            bottomRightRadius: root.backgroundRadius

            Column {
                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                    leftMargin: Appearance.spacing.xl
                }
                spacing: Appearance.spacing.xxs

                StyledText {
                    text: "Uptime"
                    color: Appearance.colors.colSubtext
                    font {
                        pixelSize: Appearance.font.pixelSize.smallest
                        capitalization: Font.AllUppercase
                        letterSpacing: Appearance.spacing.xxs / 2
                    }
                }

                StyledText {
                    text: root.formattedUptime
                    color: Appearance.colors.colOnSurface
                    font {
                        features: ({ "tnum": 1 })
                        pixelSize: Appearance.font.pixelSize.small
                    }
                }
            }
        }
    }
}
