import QtQuick
import QtQuick.Layouts
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.widgets.bar as Bar

RippleButton {
    id: rightSidebarButton

    property bool parentHovered: false

    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
    Layout.rightMargin: Appearance.rounding.screenRounding
    Layout.fillWidth: false
    Layout.fillHeight: false

    implicitWidth: indicatorsRowLayout.implicitWidth + 10 * 2
    implicitHeight: indicatorsRowLayout.implicitHeight + 5 * 2

    buttonRadius: Appearance.rounding.full
    colBackground: (rightSidebarButton.containsMouse || rightSidebarButton.parentHovered)
                   ? Appearance.colors.colLayer1Hover
                   : ColorUtils.transparentize(Appearance.colors.colLayer1Hover, 1)
    colBackgroundHover: Appearance.colors.colLayer1Hover
    colRipple: Appearance.colors.colLayer1Active
    colBackgroundToggled: Appearance.colors.colSecondaryContainer
    colBackgroundToggledHover: Appearance.colors.colSecondaryContainerHover
    colRippleToggled: Appearance.colors.colSecondaryContainerActive
    toggled: GlobalStates.sidebarRightOpen

    property color colText: toggled ? Appearance.m3colors.m3onSecondaryContainer :
                                      Appearance.colors.colOnLayer0

    Behavior on colText {
        animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(root)
    }

    onPressed: {
        GlobalStates.sidebarRightOpen = !GlobalStates.sidebarRightOpen;
    }

    RowLayout {
        id: indicatorsRowLayout
        anchors.centerIn: parent
        property real realSpacing: 15
        spacing: 0

        Revealer {
            reveal: Audio.sink?.audio?.muted ?? false
            Layout.fillHeight: true
            Layout.rightMargin: reveal ? indicatorsRowLayout.realSpacing : 0
            Behavior on Layout.rightMargin {
                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
            }
            MaterialSymbol {
                text: "volume_off"
                iconSize: Appearance.font.pixelSize.larger
                color: rightSidebarButton.colText
            }
        }

        Revealer {
            reveal: Audio.source?.audio?.muted ?? false
            Layout.fillHeight: true
            Layout.rightMargin: reveal ? indicatorsRowLayout.realSpacing : 0
            Behavior on Layout.rightMargin {
                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
            }
            MaterialSymbol {
                text: "mic_off"
                iconSize: Appearance.font.pixelSize.larger
                color: rightSidebarButton.colText
            }
        }

        Bar.HyprlandXkbIndicator {
            Layout.alignment: Qt.AlignVCenter
            Layout.rightMargin: indicatorsRowLayout.realSpacing
            color: rightSidebarButton.colText
        }

        Revealer {
            reveal: Notifications.silent || Notifications.unread > 0
            Layout.fillHeight: true
            Layout.rightMargin: reveal ? indicatorsRowLayout.realSpacing : 0
            implicitHeight: reveal ? notificationUnreadCountRow.implicitHeight : 0
            implicitWidth: reveal ? notificationUnreadCountRow.implicitWidth : 0
            Behavior on Layout.rightMargin {
                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
            }
            Bar.NotificationUnreadCount {
                id: notificationUnreadCountRow
            }
        }

        Bar.BatteryIndicator {
            Layout.alignment: Qt.AlignVCenter
            Layout.rightMargin: indicatorsRowLayout.realSpacing
            Layout.preferredHeight: Appearance.font.pixelSize.larger
            visible: Battery.available
        }

        MaterialSymbol {
            text: Network.materialSymbol
            iconSize: Appearance.font.pixelSize.larger
            color: rightSidebarButton.colText
        }

        MaterialSymbol {
            Layout.leftMargin: indicatorsRowLayout.realSpacing
            visible: BluetoothStatus.available
            text: BluetoothStatus.connected ? "bluetooth_connected" : BluetoothStatus.enabled
                                              ? "bluetooth" : "bluetooth_disabled"
            iconSize: Appearance.font.pixelSize.larger
            color: rightSidebarButton.colText
        }
    }
}
