import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.waffle.looks
import qs.services

FooterRectangle {
    id: root

    anchors.fill: parent
    implicitHeight: 230

    ColumnLayout {
        id: contentLayout

        anchors.fill: parent
        anchors.margins: 4
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 12
            Layout.rightMargin: 12
            Layout.topMargin: 8
            spacing: 8

            WText {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignLeft
                elide: Text.ElideRight
                text: "Notifications"
                font.pixelSize: Looks.font.pixelSize.large
            }

            SmallBorderedIconButton {
                icon.name: "alert-snooze"
                checked: Notifications.silent
                onClicked: {
                    Notifications.silent = !Notifications.silent;
                }
            }

            SmallBorderedIconAndTextButton {
                visible: Notifications.list.length > 0
                iconVisible: false
                text: "Clear all"
                onClicked: {
                    Notifications.discardAllNotifications();
                }
            }

        }

        WListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: Notifications.appNameList

            EmptyPlaceholder {
                visible: Notifications.list.length === 0
                anchors.centerIn: parent
            }

            delegate: WNotificationGroup {
                required property int index
                required property var modelData

                width: ListView.view.width
                notificationGroup: Notifications.groupsByAppName[modelData]
            }

        }

    }

    component EmptyPlaceholder: WText {
        horizontalAlignment: Text.AlignHCenter
        text: "No new notifications"
    }

}
