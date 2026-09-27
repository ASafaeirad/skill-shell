import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.modules.common
import qs.modules.common.m3 as M3
import qs.modules.common.widgets
import qs.services

Item {
    id: root

    implicitHeight: contentColumn.implicitHeight
    implicitWidth: contentColumn.implicitWidth

    ColumnLayout {
        id: contentColumn

        anchors.fill: parent
        spacing: 0

        // The Pomodoro timer circle
        M3.CircularProgressIndicator {
            Layout.alignment: Qt.AlignHCenter
            lineWidth: Appearance.sizes.progressBarHeight
            value: {
                return TimerService.pomodoroSecondsLeft / TimerService.pomodoroLapDuration;
            }
            implicitSize: Appearance.sizes.pomodoroProgressSize
            enableAnimation: true

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 0

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: {
                        let minutes = Math.floor(TimerService.pomodoroSecondsLeft / 60).toString().padStart(2, '0');
                        let seconds = Math.floor(TimerService.pomodoroSecondsLeft % 60).toString().padStart(2, '0');
                        return `${minutes}:${seconds}`;
                    }
                    font.pixelSize: Appearance.font.pixelSize.timer
                    color: Appearance.m3colors.m3onSurface
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: TimerService.pomodoroLongBreak ? "Long break" : TimerService.pomodoroBreak ? "Break" : "Focus"
                    font.pixelSize: Appearance.font.pixelSize.normal
                    color: Appearance.colors.colSubtext
                }

            }

            Rectangle {
                radius: Appearance.rounding.full
                color: Appearance.colors.colLayer2
                implicitWidth: Appearance.sizes.pomodoroCycleSize
                implicitHeight: implicitWidth

                anchors {
                    right: parent.right
                    bottom: parent.bottom
                }

                StyledText {
                    id: cycleText

                    anchors.centerIn: parent
                    color: Appearance.colors.colOnLayer2
                    text: TimerService.pomodoroCycle + 1
                }

            }

        }

        // The Start/Stop and Reset buttons
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: Appearance.spacing.m

            M3.Button {
                Layout.preferredWidth: Appearance.sizes.pomodoroButtonWidth
                leftPadding: Appearance.spacing.m
                rightPadding: Appearance.spacing.m
                variant: TimerService.pomodoroRunning ? "tonal" : "filled"
                text: TimerService.pomodoroRunning ? "Pause" : (TimerService.pomodoroSecondsLeft === TimerService.focusTime) ? "Start" : "Resume"
                onClicked: TimerService.togglePomodoro()
            }

            M3.Button {
                Layout.preferredWidth: Appearance.sizes.pomodoroButtonWidth
                leftPadding: Appearance.spacing.m
                rightPadding: Appearance.spacing.m
                variant: "outlined"
                text: "Reset"
                onClicked: TimerService.resetPomodoro()
                enabled: (TimerService.pomodoroSecondsLeft < TimerService.pomodoroLapDuration) || TimerService.pomodoroCycle > 0 || TimerService.pomodoroBreak
            }

        }

    }

}
