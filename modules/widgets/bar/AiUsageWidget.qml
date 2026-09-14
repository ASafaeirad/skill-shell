import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.services

MouseArea {
    id: root

    implicitWidth: rowLayout.implicitWidth
    implicitHeight: Appearance.sizes.barHeight
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

    RowLayout {
        id: rowLayout
        anchors.centerIn: parent
        spacing: Appearance.rounding.unsharpenmore

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
                spacing: Appearance.rounding.unsharpen

                Rectangle {
                    visible: providerMeter.modelData.label === "CX"
                    Layout.alignment: Qt.AlignVCenter
                    Layout.rightMargin: Appearance.rounding.unsharpenmore - providerMeter.spacing
                    implicitWidth: Appearance.rounding.unsharpen
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
