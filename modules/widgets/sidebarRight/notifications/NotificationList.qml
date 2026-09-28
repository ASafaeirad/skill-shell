import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.m3 as M3
import qs.modules.common.widgets
import qs.services

Item {
    id: root

    // Scrollable window
    NotificationListView {
        id: listview

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: statusRow.top
        anchors.bottomMargin: 5
        clip: true
        layer.enabled: true
        popup: false

        layer.effect: OpacityMask {

            maskSource: Rectangle {
                width: listview.width
                height: listview.height
                radius: Appearance.rounding.normal
            }

        }

    }

    // Placeholder when list is empty
    PagePlaceholder {
        shown: Notifications.list.length === 0
        icon: "notifications_active"
        description: "Nothing"
        shape: MaterialShape.Shape.Ghostish
        descriptionHorizontalAlignment: Text.AlignHCenter
    }

    M3.ButtonGroup {
        id: statusRow

        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }

        M3.Button {
            Layout.fillWidth: false
            variant: "tonal"
            toggleable: true
            materialIcon: "notifications_paused"
            selected: Notifications.silent
            onClicked: () => {
                Notifications.silent = !Notifications.silent;
            }
        }

        M3.Button {
            enabled: false
            Layout.fillWidth: true
            variant: "tonal"
            text: "%1 notifications".arg(Notifications.list.length)
        }

        M3.Button {
            Layout.fillWidth: false
            variant: "tonal"
            materialIcon: "delete_sweep"
            onClicked: () => {
                Notifications.discardAllNotifications();
            }
        }

    }

}
