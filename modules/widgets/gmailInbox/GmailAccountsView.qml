pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ColumnLayout {
    id: root
    signal backRequested()
    spacing: 0

    RowLayout {
        Layout.fillWidth: true
        Layout.margins: Appearance.spacing.m
        spacing: Appearance.spacing.s

        MaterialSymbol {
            text: "arrow_back"
            iconSize: Appearance.font.pixelSize.large
            color: Appearance.colors.colOnLayer2
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.backRequested()
            }
        }
        StyledText {
            Layout.fillWidth: true
            text: "Accounts"
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colOnSurface
        }
    }

    Flickable {
        Layout.fillWidth: true
        implicitHeight: Math.min(accountList.implicitHeight, Appearance.sizes.barHeight * 7)
        contentHeight: accountList.implicitHeight
        clip: true

        ColumnLayout {
            id: accountList
            width: parent.width
            spacing: 0

            Repeater {
                model: Gmail.configuredAccounts
                delegate: ColumnLayout {
                    id: accountRow
                    required property var modelData
                    property bool editing: false
                    Layout.fillWidth: true
                    Layout.leftMargin: Appearance.spacing.m
                    Layout.rightMargin: Appearance.spacing.m
                    spacing: Appearance.spacing.xs

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.topMargin: Appearance.spacing.s
                        Layout.bottomMargin: Appearance.spacing.s
                        spacing: Appearance.spacing.m
                        Rectangle {
                            implicitWidth: Appearance.spacing.m
                            implicitHeight: implicitWidth
                            radius: Appearance.rounding.full
                            color: Appearance.m3colors[accountRow.modelData.color] ?? Appearance.colors.colPrimary
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Appearance.spacing.xxs
                            StyledText {
                                Layout.fillWidth: true
                                text: accountRow.modelData.label || accountRow.modelData.email
                                font.pixelSize: Appearance.font.pixelSize.smallie
                                color: Appearance.colors.colOnSurface
                                elide: Text.ElideRight
                            }
                            StyledText {
                                Layout.fillWidth: true
                                text: accountRow.modelData.email
                                font.pixelSize: Appearance.font.pixelSize.smallest
                                color: Appearance.colors.colSubtext
                                elide: Text.ElideRight
                            }
                        }
                        MaterialSymbol {
                            text: accountRow.editing ? "close" : "edit"
                            iconSize: Appearance.font.pixelSize.large
                            color: Appearance.colors.colSubtext
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: accountRow.editing = !accountRow.editing
                            }
                        }
                    }

                    ColumnLayout {
                        visible: accountRow.editing
                        Layout.fillWidth: true
                        Layout.bottomMargin: Appearance.spacing.m
                        spacing: Appearance.spacing.s

                        MaterialTextField {
                            id: labelField
                            Layout.fillWidth: true
                            placeholderText: "Account label"
                            text: accountRow.modelData.label || accountRow.modelData.email
                            onAccepted: {
                                Gmail.setAccountLabel(accountRow.modelData.id, text);
                                accountRow.editing = false;
                            }
                        }
                        RowLayout {
                            spacing: Appearance.spacing.s
                            Repeater {
                                model: Gmail.accountColorKeys
                                delegate: Rectangle {
                                    id: colorChoice
                                    required property string modelData
                                    implicitWidth: Appearance.spacing.xxl
                                    implicitHeight: implicitWidth
                                    radius: Appearance.rounding.full
                                    color: accountRow.modelData.color === modelData
                                        ? Appearance.colors.colSurfaceContainerHighest
                                        : "transparent"
                                    Rectangle {
                                        anchors.centerIn: parent
                                        width: Appearance.spacing.m
                                        height: width
                                        radius: Appearance.rounding.full
                                        color: Appearance.m3colors[colorChoice.modelData]
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: Gmail.setAccountColor(accountRow.modelData.id, colorChoice.modelData)
                                    }
                                }
                            }
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            Item { Layout.fillWidth: true }
                            RippleButtonWithIcon {
                                materialIcon: "delete"
                                mainText: "Remove"
                                onClicked: Gmail.removeAccount(accountRow.modelData.id)
                            }
                            RippleButtonWithIcon {
                                materialIcon: "check"
                                mainText: "Save label"
                                onClicked: {
                                    Gmail.setAccountLabel(accountRow.modelData.id, labelField.text);
                                    accountRow.editing = false;
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    ColumnLayout {
        visible: !Gmail.credentialsAvailable
        Layout.fillWidth: true
        Layout.margins: Appearance.spacing.m
        spacing: Appearance.spacing.s
        StyledText {
            Layout.fillWidth: true
            text: "Add your Google OAuth desktop credentials to sign in."
            color: Appearance.colors.colSubtext
            wrapMode: Text.Wrap
        }
        MaterialTextField {
            id: clientIdField
            Layout.fillWidth: true
            placeholderText: "OAuth client ID"
            text: Gmail.savedClientId
        }
        MaterialTextField {
            id: clientSecretField
            Layout.fillWidth: true
            placeholderText: Gmail.hasSavedClientSecret ? "Client secret stored in keyring" : "OAuth client secret"
            echoMode: TextInput.Password
        }
    }

    StyledText {
        visible: Gmail.statusMessage.length > 0 && (Gmail.signingIn || Gmail.lastOutcome !== "success")
        Layout.fillWidth: true
        Layout.leftMargin: Appearance.spacing.m
        Layout.rightMargin: Appearance.spacing.m
        text: Gmail.statusMessage
        font.pixelSize: Appearance.font.pixelSize.smaller
        color: Gmail.lastOutcome === "error" || Gmail.lastOutcome === "invalid"
            ? Appearance.colors.colError : Appearance.colors.colSubtext
        wrapMode: Text.Wrap
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: Appearance.spacing.xxs / 2
        color: Appearance.colors.colLayer0Border
    }
    RowLayout {
        Layout.fillWidth: true
        Layout.margins: Appearance.spacing.m
        StyledText {
            Layout.fillWidth: true
            text: `Poll every ${Gmail.refreshIntervalMinutes} min`
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: Appearance.colors.colSubtext
        }
        RippleButtonWithIcon {
            materialIcon: "add"
            mainText: Gmail.signingIn ? "Waiting for Google" : "Add account"
            enabled: !Gmail.signingIn
            onClicked: Gmail.signIn(Gmail.credentialsAvailable ? Gmail.savedClientId : clientIdField.text,
                                    Gmail.credentialsAvailable ? "" : clientSecretField.text)
        }
    }
}
