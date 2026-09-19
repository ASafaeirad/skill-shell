import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.services

MouseArea {
    id: root

    property bool vertical: false

    implicitWidth: root.vertical ? Appearance.sizes.verticalBarWidth : (rowLayout.implicitWidth + Appearance.font.pixelSize.smaller * 2)
    implicitHeight: root.vertical ? (colLayout.implicitHeight + Appearance.spacing.s * 2) : Appearance.sizes.barHeight
    hoverEnabled: !Config.options.bar.tooltips.clickToShow
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    cursorShape: Qt.PointingHandCursor

    function progressColor(provider) {
        if (AiUsage.isStale(provider))
            return Appearance.colors.colOutline;
        const remaining = AiUsage.remainingPercent(provider);
        if (remaining <= 20)
            return Appearance.colors.colError;
        if (remaining <= 40)
            return Appearance.colors.colTertiary;
        return Appearance.colors.colPrimary;
    }

    onClicked: event => {
        if (event.button === Qt.RightButton)
            AiUsage.togglePaused();
        else if (event.button === Qt.LeftButton)
            AiUsage.sync();
    }

    ColumnLayout {
        id: colLayout
        visible: root.vertical
        anchors.centerIn: parent
        spacing: Appearance.spacing.xs

        Repeater {
            model: [
                {
                    provider: AiUsage.claude,
                    label: "CL"
                },
                {
                    provider: AiUsage.codex,
                    label: "CX"
                }
            ]

            delegate: ColumnLayout {
                id: providerMeterCol
                required property var modelData

                Layout.alignment: Qt.AlignHCenter
                spacing: 2

                Rectangle {
                    visible: providerMeterCol.modelData.label === "CX"
                    Layout.alignment: Qt.AlignHCenter
                    Layout.bottomMargin: Appearance.spacing.xxs
                    implicitWidth: Appearance.font.pixelSize.normal
                    implicitHeight: Appearance.spacing.xxs
                    radius: Appearance.rounding.full
                    color: Appearance.colors.colOnLayer1Inactive
                }

                IconCircularProgress {
                    id: progressCol
                    Layout.alignment: Qt.AlignHCenter
                    implicitSize: Appearance.font.pixelSize.huge
                    lineWidth: 2
                    value: (AiUsage.remainingPercent(providerMeterCol.modelData.provider) ?? 0) / 100
                    colPrimary: root.progressColor(providerMeterCol.modelData.provider)
                    enableAnimation: true
                    animationDuration: Appearance.animation.elementMove.duration
                    opacity: AiUsage.paused ? 0.5 : 1

                    Behavior on opacity {
                        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                    }
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    font.pixelSize: Appearance.font.pixelSize.smallest
                    text: providerMeterCol.modelData.label
                }
            }
        }
    }

    RowLayout {
        id: rowLayout
        visible: !root.vertical
        anchors.centerIn: parent
        spacing: Appearance.spacing.xs

        Repeater {
            model: [
                {
                    provider: AiUsage.claude,
                    label: "CL"
                },
                {
                    provider: AiUsage.codex,
                    label: "CX"
                }
            ]

            delegate: RowLayout {
                id: providerMeter

                required property var modelData

                Layout.alignment: Qt.AlignVCenter
                spacing: Appearance.spacing.s

                Rectangle {
                    visible: providerMeter.modelData.label === "CX"
                    Layout.alignment: Qt.AlignVCenter
                    Layout.rightMargin: Appearance.spacing.xxs
                    Layout.leftMargin: Appearance.spacing.xxs
                    implicitWidth: Appearance.spacing.xxs
                    implicitHeight: Appearance.font.pixelSize.normal
                    radius: Appearance.rounding.full
                    color: Appearance.colors.colOnLayer1Inactive
                }

                IconCircularProgress {
                    id: progress

                    implicitSize: Appearance.font.pixelSize.huge
                    lineWidth: 3
                    value: (AiUsage.remainingPercent(providerMeter.modelData.provider) ?? 0) / 100
                    colPrimary: root.progressColor(providerMeter.modelData.provider)
                    enableAnimation: true
                    animationDuration: Appearance.animation.elementMove.duration
                    opacity: AiUsage.paused ? 0.5 : 1

                    Behavior on opacity {
                        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                    }
                }

                StyledText {
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    text: providerMeter.modelData.label
                }
            }
        }
    }

    AiUsagePopup {
        hoverTarget: root
    }
}
