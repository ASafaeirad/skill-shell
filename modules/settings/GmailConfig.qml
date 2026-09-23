import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.services

ContentPage {
    forceWidth: true

    ContentSection {
        icon: "mail"
        title: "Gmail"

        ConfigSwitch {
            buttonIcon: "visibility"
            text: "Show unread counts in the bar"
            configKey: "gmail.enable"
        }

        ConfigSpinBox {
            icon: "schedule"
            text: "Refresh interval in minutes"
            configKey: "gmail.refreshIntervalMinutes"
            from: 1
            to: 60
            stepSize: 1
        }

        ConfigSwitch {
            buttonIcon: "notifications"
            text: "Notify when new mail arrives"
            configKey: "gmail.notifyOnNewMail"
        }

        StyledText {
            Layout.fillWidth: true
            text: "Only unread messages that were absent from the previous sync raise a notification, and more than three at once collapse into one summary. Silence a single inbox from its row below."
            color: Appearance.colors.colSubtext
            wrapMode: Text.Wrap
        }
    }

    ContentSection {
        icon: "key"
        title: "Google OAuth"

        StyledText {
            Layout.fillWidth: true
            text: "Create a Google OAuth client of type Desktop app and enable the Gmail API. Mail actions require Gmail modify access. Existing accounts may need to sign in again."
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

        ConfigRow {
            RippleButtonWithIcon {
                materialIcon: "save"
                mainText: "Save credentials"
                onClicked: Gmail.saveCredentials(clientIdField.text, clientSecretField.text)
            }

            RippleButtonWithIcon {
                primary: true
                materialIcon: "login"
                mainText: Gmail.signingIn ? "Waiting for Google" : "Sign in with Google"
                enabled: !Gmail.signingIn
                onClicked: Gmail.signIn(clientIdField.text, clientSecretField.text)
            }
        }

        StyledText {
            Layout.fillWidth: true
            visible: Gmail.statusMessage.length > 0
            text: Gmail.statusMessage
            color: Gmail.lastOutcome === "expired" || Gmail.lastOutcome === "network"
                ? Appearance.colors.colError
                : Appearance.colors.colSubtext
            wrapMode: Text.Wrap
        }

        StyledText {
            Layout.fillWidth: true
            text: "Google expires refresh tokens after 7 days while the consent screen is in Testing. Set it to In production and accept the unverified-app warning once to keep the sign-in."
            color: Appearance.colors.colSubtext
            wrapMode: Text.Wrap
        }
    }

    ContentSection {
        visible: Gmail.configuredAccounts.length > 0
        icon: "manage_accounts"
        title: "Signed-in accounts"

        Repeater {
            model: Gmail.configuredAccounts

            delegate: Rectangle {
                id: accountRow

                required property var modelData
                Layout.fillWidth: true
                implicitHeight: accountLayout.implicitHeight + Appearance.spacing.s * 2
                radius: Appearance.rounding.small
                color: Appearance.colors.colLayer1

                RowLayout {
                    id: accountLayout
                    anchors {
                        fill: parent
                        leftMargin: Appearance.spacing.s
                        rightMargin: Appearance.spacing.s
                        topMargin: Appearance.spacing.s
                        bottomMargin: Appearance.spacing.s
                    }
                    spacing: Appearance.spacing.s

                    Rectangle {
                        Layout.alignment: Qt.AlignVCenter
                        implicitWidth: Appearance.spacing.m
                        implicitHeight: Appearance.spacing.m
                        radius: Appearance.rounding.full
                        color: Appearance.m3colors[accountRow.modelData.color]
                            ?? Appearance.colors.colPrimary
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Appearance.spacing.xxs

                        StyledText {
                            text: accountRow.modelData.label || accountRow.modelData.email
                            color: Appearance.colors.colOnLayer1
                            font.pixelSize: Appearance.font.pixelSize.normal
                        }

                        StyledText {
                            visible: accountRow.modelData.label !== accountRow.modelData.email
                            text: accountRow.modelData.email
                            color: Appearance.colors.colSubtext
                            font.pixelSize: Appearance.font.pixelSize.small
                        }
                    }

                    MaterialSymbol {
                        Layout.alignment: Qt.AlignVCenter
                        visible: Gmail.notifyOnNewMail
                        text: accountRow.modelData.notify === false ? "notifications_off" : "notifications_active"
                        iconSize: Appearance.font.pixelSize.larger
                        color: accountRow.modelData.notify === false ? Appearance.colors.colSubtext
                                                                     : Appearance.colors.colOnLayer1

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Gmail.setAccountNotify(accountRow.modelData.id,
                                                              accountRow.modelData.notify === false)
                        }
                    }

                    StyledSwitch {
                        checked: accountRow.modelData.enabled !== false
                        onClicked: Gmail.setAccountEnabled(accountRow.modelData.id, checked)
                    }

                    RippleButtonWithIcon {
                        materialIcon: "delete"
                        mainText: "Remove"
                        onClicked: Gmail.removeAccount(accountRow.modelData.id)
                    }
                }
            }
        }
    }
}
