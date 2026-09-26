import QtQuick
import QtQuick.Layouts
import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.services

MouseArea {
    id: root

    implicitWidth: content.implicitWidth + Appearance.spacing.s * 2
    implicitHeight: Appearance.sizes.barHeight
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    cursorShape: Qt.PointingHandCursor
    onClicked: event => {
        if (event.button === Qt.RightButton)
            Gmail.sync();
        else
            GlobalStates.gmailInbox?.toggle();
    }

    BarAnchor {
        name: "gmail"
    }

    readonly property bool isRequesting: Gmail.syncing || Gmail.acting

    function accountColor(account) {
        const paletteColor = Appearance.m3colors[account.color];
        return paletteColor ?? Appearance.colors.colPrimary;
    }

    RowLayout {
        id: content
        anchors.centerIn: parent
        spacing: Appearance.spacing.xs

        Repeater {
            model: Gmail.accounts

            delegate: RowLayout {
                id: accountCount

                required property var modelData
                spacing: Appearance.spacing.s

                Rectangle {
                    Layout.alignment: Qt.AlignVCenter
                    implicitWidth: Appearance.spacing.s
                    implicitHeight: Appearance.spacing.s
                    radius: Appearance.rounding.full
                    color: root.accountColor(accountCount.modelData)
                }

                StyledText {
                    Layout.alignment: Qt.AlignVCenter
                    text: accountCount.modelData.unread ?? ""
                    color: accountCount.modelData.error ? Appearance.colors.colError :
                                                          Appearance.colors.colOnLayer1
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.family: Appearance.font.family.numbers
                }
            }
        }
    }
}


