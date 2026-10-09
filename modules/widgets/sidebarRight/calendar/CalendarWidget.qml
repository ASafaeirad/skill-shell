import QtQuick
import QtQuick.Layouts
import "calendar_layout.js" as CalendarLayout
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.m3 as M3

Item {
    property int monthShift: 0
    property var viewingDate: CalendarLayout.getDateInXMonthsTime(monthShift)
    property var calendarLayout: CalendarLayout.getCalendarLayout(viewingDate, monthShift === 0)

    // Layout.topMargin: 10
    anchors.topMargin: 10
    width: calendarColumn.width
    implicitHeight: calendarColumn.height + 10 * 2
    Keys.onPressed: (event) => {
        if ((event.key === Qt.Key_PageDown || event.key === Qt.Key_PageUp) && event.modifiers === Qt.NoModifier) {
            if (event.key === Qt.Key_PageDown)
                monthShift++;
            else if (event.key === Qt.Key_PageUp)
                monthShift--;
            event.accepted = true;
        }
    }

    MouseArea {
        anchors.fill: parent
        onWheel: (event) => {
            if (event.angleDelta.y > 0)
                monthShift--;
            else if (event.angleDelta.y < 0)
                monthShift++;
        }
    }

    ColumnLayout {
        id: calendarColumn

        anchors.centerIn: parent
        spacing: 5

        // Calendar header
        RowLayout {
            Layout.fillWidth: true
            spacing: 5

            M3.Button {
                clip: true
                variant: "text"
                text: `${monthShift != 0 ? "• " : ""}${viewingDate.toLocaleDateString(Qt.locale(), "MMMM yyyy")}`
                downAction: () => {
                    monthShift = 0;
                }

                M3.Tooltip {
                    text: "Jump to current month"
                    extraVisibleCondition: monthShift !== 0
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: false
            }

            M3.IconButton {
                materialIcon: "chevron_left"
                downAction: () => {
                    monthShift--;
                }
            }

            M3.IconButton {
                materialIcon: "chevron_right"
                downAction: () => {
                    monthShift++;
                }
            }

        }

        // Week days row
        RowLayout {
            id: weekDaysRow

            Layout.alignment: Qt.AlignHCenter
            Layout.fillHeight: false
            spacing: 5

            Repeater {
                model: CalendarLayout.weekDays

                // Column labels, not controls: plain text in a day-sized cell.
                delegate: StyledText {
                    Layout.preferredWidth: Appearance.sizes.calendarDaySize
                    Layout.preferredHeight: Appearance.sizes.calendarDaySize
                    text: modelData.day
                    color: Appearance.colors.colOnSurface
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.weight: Font.DemiBold
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

            }

        }

        // Real week rows
        Repeater {
            id: calendarRows

            // model: calendarLayout
            model: 6

            delegate: RowLayout {
                Layout.alignment: Qt.AlignHCenter
                Layout.fillHeight: false
                spacing: 5

                Repeater {
                    model: Array(7).fill(modelData)

                    delegate: CalendarDayButton {
                        day: calendarLayout[modelData][index].day
                        isToday: calendarLayout[modelData][index].today
                    }

                }

            }

        }

    }

}
