import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.ii.sidebarRight.notifications
import qs.services

Rectangle {
    id: root

    radius: Appearance.rounding.normal
    color: Appearance.colors.colLayer1

    NotificationList {
        anchors.fill: parent
        anchors.margins: 5
    }

}
