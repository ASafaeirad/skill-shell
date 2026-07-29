import QtQuick
import qs.modules.common
import qs.modules.common.widgets
import qs.services

MaterialSymbol {
    id: root

    readonly property bool showUnreadCount: Config.options.bar.indicators.notifications.showUnreadCount

    text: Notifications.silent ? "notifications_paused" : "notifications"
    iconSize: Appearance.font.pixelSize.larger
    color: rightSidebarButton.colText

    Rectangle {
        id: notifPing

        visible: !Notifications.silent && Notifications.unread > 0
        radius: Appearance.rounding.full
        color: Appearance.colors.colOnLayer0
        z: 1
        implicitHeight: root.showUnreadCount ? Math.max(notificationCounterText.implicitWidth, notificationCounterText.implicitHeight) : 8
        implicitWidth: implicitHeight

        anchors {
            right: parent.right
            top: parent.top
            rightMargin: root.showUnreadCount ? 0 : 1
            topMargin: root.showUnreadCount ? 0 : 3
        }

        StyledText {
            id: notificationCounterText

            visible: root.showUnreadCount
            anchors.centerIn: parent
            font.pixelSize: Appearance.font.pixelSize.smallest
            color: Appearance.colors.colLayer0
            text: Notifications.unread
        }

    }

}
