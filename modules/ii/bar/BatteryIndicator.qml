import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
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

    implicitWidth: batteryProgress.implicitWidth
    implicitHeight: Appearance.sizes.barHeight
    hoverEnabled: !Config.options.bar.tooltips.clickToShow

    ClippedProgressBar {
        id: batteryProgress

        anchors.centerIn: parent
        value: percentage
        highlightColor: {
            if (root.isCritical)
                return criticalPulse.bright ? Appearance.m3colors.m3error : ColorUtils.transparentize(Appearance.m3colors.m3error, 0.35);

            if (root.isLow)
                return Appearance.m3colors.m3error;

            return Appearance.colors.colOnSecondaryContainer;
        }

        Item {
            anchors.centerIn: parent
            width: batteryProgress.valueBarWidth
            height: batteryProgress.valueBarHeight

            RowLayout {
                spacing: 0

                anchors {
                    horizontalCenter: parent.horizontalCenter
                    bottom: parent.bottom
                    bottomMargin: (parent.height - height) / 2
                }

                MaterialSymbol {
                    id: alertIcon

                    Layout.alignment: Qt.AlignVCenter
                    Layout.leftMargin: -2
                    Layout.rightMargin: -2
                    fill: 1
                    text: "battery_alert"
                    iconSize: Appearance.font.pixelSize.smaller
                    visible: root.isCritical
                }

                MaterialSymbol {
                    id: boltIcon

                    Layout.alignment: Qt.AlignVCenter
                    Layout.leftMargin: -2
                    Layout.rightMargin: -2
                    fill: 1
                    text: "bolt"
                    iconSize: Appearance.font.pixelSize.smaller
                    visible: isCharging && percentage < 1 && !root.isCritical
                }

                StyledText {
                    Layout.alignment: Qt.AlignVCenter
                    font: batteryProgress.font
                    text: batteryProgress.text
                }

            }

        }

        Behavior on highlightColor {
            ColorAnimation {
                duration: Appearance.animation.elementMoveFast.duration
                easing.type: Appearance.animation.elementMoveFast.type
                easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
            }

        }

    }

    // Active pulse while critically low and unplugged
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

    BatteryPopup {
        id: batteryPopup

        hoverTarget: root
    }

}
