import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.widgets.bar as Bar
import qs.services

MouseArea {
    id: root

    property bool borderless: Config.options.bar.borderless
    readonly property var chargeState: Battery.chargeState
    readonly property bool isCharging: Battery.isCharging
    readonly property bool isPluggedIn: Battery.isPluggedIn
    readonly property real percentage: Battery.percentage
    readonly property bool isLow: Battery.isLowAndNotCharging
    readonly property bool isCritical: Battery.isCriticalAndNotCharging

    implicitHeight: batteryProgress.implicitHeight
    hoverEnabled: !Config.options.bar.tooltips.clickToShow

    ClippedProgressBar {
        id: batteryProgress

        anchors.centerIn: parent
        vertical: true
        valueBarWidth: 20
        valueBarHeight: 36
        value: percentage
        highlightColor: {
            if (root.isCritical)
                return criticalPulse.bright ? Appearance.m3colors.m3error : ColorUtils.transparentize(Appearance.m3colors.m3error, 0.35);

            if (root.isLow)
                return Appearance.m3colors.m3error;

            return Appearance.colors.colOnSecondaryContainer;
        }

        font {
            pixelSize: 13
            weight: Font.DemiBold
        }

        Behavior on highlightColor {
            ColorAnimation {
                duration: Appearance.animation.elementMoveFast.duration
                easing.type: Appearance.animation.elementMoveFast.type
                easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
            }

        }

        textMask: Item {
            anchors.centerIn: parent
            width: batteryProgress.valueBarWidth
            height: batteryProgress.valueBarHeight

            Column {
                anchors.centerIn: parent
                spacing: -4

                MaterialSymbol {
                    id: boltIcon

                    anchors.horizontalCenter: parent.horizontalCenter
                    fill: 1
                    text: {
                        if (root.isCritical)
                            return "battery_alert";

                        if (batteryProgress.value == 1)
                            return "check";

                        if (root.isCharging)
                            return "bolt";

                        return Icons.getBatteryIcon(Battery.percentage * 100);
                    }
                    iconSize: Appearance.font.pixelSize.normal
                    animateChange: true
                }

                StyledText {
                    visible: text.length <= 2
                    anchors.horizontalCenter: parent.horizontalCenter
                    font: batteryProgress.font
                    text: batteryProgress.text
                }

            }

        }

    }

    Timer {
        id: criticalPulse

        property bool bright: true

        interval: Appearance.animation.elementMoveFast.duration * 3
        running: root.isCritical
        repeat: true
        onTriggered: bright = !bright
        onRunningChanged: {
            if (!running) {
                bright = true;
            }
        }
    }

    Bar.BatteryPopup {
        id: batteryPopup

        hoverTarget: root
    }

}
