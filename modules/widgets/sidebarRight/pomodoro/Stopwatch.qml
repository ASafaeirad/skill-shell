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
    id: stopwatchTab

    Layout.fillWidth: true
    Layout.fillHeight: true

    Item {
        anchors {
            fill: parent
            topMargin: 8
            leftMargin: 16
            rightMargin: 16
        }

        // Elapsed
        RowLayout {
            id: elapsedIndicator

            spacing: 0

            anchors {
                top: undefined
                verticalCenter: parent.verticalCenter
                left: controlButtons.left
                leftMargin: 6
            }

            StyledText {
                // Layout.preferredWidth: elapsedIndicator.width * 0.6 // Prevent shakiness
                font.pixelSize: Appearance.font.pixelSize.timer
                color: Appearance.m3colors.m3onSurface
                text: {
                    let totalSeconds = Math.floor(TimerService.stopwatchTime) / 100;
                    let minutes = Math.floor(totalSeconds / 60).toString().padStart(2, '0');
                    let seconds = Math.floor(totalSeconds % 60).toString().padStart(2, '0');
                    return `${minutes}:${seconds}`;
                }
            }

            StyledText {
                Layout.fillWidth: true
                font.pixelSize: Appearance.font.pixelSize.timer
                color: Appearance.colors.colSubtext
                text: {
                    return `:<sub>${(Math.floor(TimerService.stopwatchTime) % 100).toString().padStart(2, '0')}</sub>`;
                }
            }

            states: State {
                name: "hasLaps"
                when: TimerService.stopwatchLaps.length > 0

                AnchorChanges {
                    target: elapsedIndicator
                    anchors.top: parent.top
                    anchors.verticalCenter: undefined
                    anchors.left: controlButtons.left
                }

            }

            transitions: Transition {
                AnchorAnimation {
                    duration: Appearance.animation.elementMoveFast.duration
                    easing.type: Appearance.animation.elementMoveFast.type
                    easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
                }

            }

        }

        // Laps
        StyledListView {
            id: lapsList

            spacing: 4
            clip: true
            popin: true

            anchors {
                top: elapsedIndicator.bottom
                bottom: controlButtons.top
                left: parent.left
                right: parent.right
                topMargin: 16
                bottomMargin: 16
            }

            model: ScriptModel {
                values: TimerService.stopwatchLaps.map((v, i, arr) => {
                    return arr[arr.length - 1 - i];
                })
            }

            delegate: M3.Card {
                id: lapItem

                required property int index
                required property var modelData
                width: lapsList.width
                padding: Appearance.spacing.xs
                spacing: 0

                RowLayout {
                    id: lapRow
                    Layout.fillWidth: true

                    StyledText {
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colSubtext
                        text: `${TimerService.stopwatchLaps.length - lapItem.index}.`
                    }

                    StyledText {
                        font.pixelSize: Appearance.font.pixelSize.small
                        text: {
                            const lapTime = lapItem.modelData;
                            const _10ms = (Math.floor(lapTime) % 100).toString().padStart(2, '0');
                            const totalSeconds = Math.floor(lapTime) / 100;
                            const minutes = Math.floor(totalSeconds / 60).toString().padStart(2, '0');
                            const seconds = Math.floor(totalSeconds % 60).toString().padStart(2, '0');
                            return `${minutes}:${seconds}.${_10ms}`;
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    StyledText {
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colPrimary
                        text: {
                            const originalIndex = TimerService.stopwatchLaps.length - lapItem.index - 1;
                            const lastTime = originalIndex > 0 ? TimerService.stopwatchLaps[originalIndex - 1] : 0;
                            const lapTime = lapItem.modelData - lastTime;
                            const _10ms = (Math.floor(lapTime) % 100).toString().padStart(2, '0');
                            const totalSeconds = Math.floor(lapTime) / 100;
                            const minutes = Math.floor(totalSeconds / 60).toString().padStart(2, '0');
                            const seconds = Math.floor(totalSeconds % 60).toString().padStart(2, '0');
                            return `+${minutes == "00" ? "" : minutes + ":"}${seconds}.${_10ms}`;
                        }
                    }

                }

            }

        }

        RowLayout {
            id: controlButtons

            spacing: Appearance.spacing.xxs * 2

            anchors {
                horizontalCenter: parent.horizontalCenter
                bottom: parent.bottom
                bottomMargin: 6
            }

            M3.Button {
                Layout.preferredWidth: Appearance.sizes.pomodoroButtonWidth
                leftPadding: Appearance.spacing.m
                rightPadding: Appearance.spacing.m
                variant: TimerService.stopwatchRunning ? "tonal" : "filled"
                text: TimerService.stopwatchRunning ? "Pause" : TimerService.stopwatchTime === 0 ? "Start" : "Resume"
                onClicked: {
                    TimerService.toggleStopwatch();
                }
            }

            M3.Button {
                Layout.preferredWidth: Appearance.sizes.pomodoroButtonWidth
                leftPadding: Appearance.spacing.m
                rightPadding: Appearance.spacing.m
                variant: TimerService.stopwatchRunning ? "tonal" : "outlined"
                text: TimerService.stopwatchRunning ? "Lap" : "Reset"
                onClicked: {
                    if (TimerService.stopwatchRunning)
                        TimerService.stopwatchRecordLap();
                    else
                        TimerService.stopwatchReset();
                }
                enabled: TimerService.stopwatchTime > 0 || Persistent.states.timer.stopwatch.laps.length > 0
            }

        }

    }

}
