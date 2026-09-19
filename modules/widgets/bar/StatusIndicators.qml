import QtQuick
import QtQuick.Layouts
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.widgets.bar as Bar
import qs.modules.widgets.verticalBar as VBar

RippleButton {
    id: rightSidebarButton

    property bool vertical: false
    property bool parentHovered: false

    Layout.alignment: rightSidebarButton.vertical ? (Qt.AlignBottom | Qt.AlignHCenter) : (Qt.AlignRight | Qt.AlignVCenter)
    Layout.rightMargin: rightSidebarButton.vertical ? 0 : Appearance.rounding.screenRounding
    Layout.bottomMargin: rightSidebarButton.vertical ? Appearance.rounding.screenRounding : 0
    Layout.fillWidth: false
    Layout.fillHeight: false

    implicitWidth: rightSidebarButton.vertical ? (indicatorsColumnLayout.implicitWidth + 6 * 2) : (indicatorsRowLayout.implicitWidth + 10 * 2)
    implicitHeight: rightSidebarButton.vertical ? (indicatorsColumnLayout.implicitHeight + 4 * 2) : (indicatorsRowLayout.implicitHeight + 5 * 2)

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

    // Horizontal layout
    RowLayout {
        id: indicatorsRowLayout
        visible: !rightSidebarButton.vertical
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

    // Vertical layout
    ColumnLayout {
        id: indicatorsColumnLayout
        visible: rightSidebarButton.vertical
        anchors.centerIn: parent
        property real realSpacing: 6
        spacing: 0

        Revealer {
            vertical: true
            reveal: Audio.sink?.audio?.muted ?? false
            Layout.fillWidth: true
            Layout.bottomMargin: reveal ? indicatorsColumnLayout.realSpacing : 0
            Behavior on Layout.bottomMargin {
                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
            }
            MaterialSymbol {
                text: "volume_off"
                iconSize: Appearance.font.pixelSize.larger
                color: rightSidebarButton.colText
            }
        }

        Revealer {
            vertical: true
            reveal: Audio.source?.audio?.muted ?? false
            Layout.fillWidth: true
            Layout.bottomMargin: reveal ? indicatorsColumnLayout.realSpacing : 0
            Behavior on Layout.topMargin {
                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
            }
            MaterialSymbol {
                text: "mic_off"
                iconSize: Appearance.font.pixelSize.larger
                color: rightSidebarButton.colText
            }
        }

        Bar.HyprlandXkbIndicator {
            vertical: true
            Layout.alignment: Qt.AlignHCenter
            Layout.bottomMargin: indicatorsColumnLayout.realSpacing
            color: rightSidebarButton.colText
        }

        Revealer {
            vertical: true
            reveal: Notifications.silent || Notifications.unread > 0
            Layout.fillWidth: true
            Layout.bottomMargin: reveal ? indicatorsColumnLayout.realSpacing : 0
            implicitHeight: reveal ? notificationUnreadCountCol.implicitHeight : 0
            implicitWidth: reveal ? notificationUnreadCountCol.implicitWidth : 0
            Behavior on Layout.bottomMargin {
                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
            }
            Bar.NotificationUnreadCount {
                id: notificationUnreadCountCol
            }
        }

        VBar.BatteryIndicator {
            Layout.alignment: Qt.AlignHCenter
            Layout.bottomMargin: indicatorsColumnLayout.realSpacing
            Layout.preferredWidth: 20
            Layout.preferredHeight: 36
            visible: Battery.available
        }

        MaterialSymbol {
            text: Network.materialSymbol
            iconSize: Appearance.font.pixelSize.larger
            color: rightSidebarButton.colText
        }

        MaterialSymbol {
            Layout.topMargin: indicatorsColumnLayout.realSpacing
            visible: BluetoothStatus.available
            text: BluetoothStatus.connected ? "bluetooth_connected" : BluetoothStatus.enabled ? "bluetooth" : "bluetooth_disabled"
            iconSize: Appearance.font.pixelSize.larger
            color: rightSidebarButton.colText
        }
    }
}
