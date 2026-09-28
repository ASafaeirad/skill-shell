pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.m3 as M3

ColumnLayout {
    id: root
    signal backRequested()
    spacing: 0

    RowLayout {
        Layout.fillWidth: true
        Layout.margins: Appearance.spacing.m
        spacing: Appearance.spacing.s

        M3.IconButton {
            size: "xsmall"
            materialIcon: "arrow_back"
            tooltip: "Back to inbox"
            onClicked: root.backRequested()
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
                    onEditingChanged: {
                        if (editing)
                            labelField.forceActiveFocus();
                    }
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
                        M3.IconButton {
                            size: "xsmall"
                            materialIcon: accountRow.editing ? "close" : "edit"
                            tooltip: accountRow.editing ? "Stop editing" : "Edit account"
                            onClicked: accountRow.editing = !accountRow.editing
                        }
                    }

                    ColumnLayout {
                        visible: accountRow.editing
                        Layout.fillWidth: true
                        Layout.bottomMargin: Appearance.spacing.m
                        spacing: Appearance.spacing.s

                        M3.TextField {
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
                                delegate: M3.IconButton {
                                    id: colorChoice
                                    required property string modelData
                                    size: "xsmall"
                                    toggleable: true
                                    selectedVariant: "tonal"
                                    dotColor: Appearance.m3colors[colorChoice.modelData]
                                    selected: accountRow.modelData.color === colorChoice.modelData
                                    onClicked: Gmail.setAccountColor(accountRow.modelData.id, colorChoice.modelData)
                                }
                            }
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            Item { Layout.fillWidth: true }
                            M3.Button {
                                variant: "text"
                                error: true
                                materialIcon: "delete"
                                text: "Remove"
                                onClicked: Gmail.removeAccount(accountRow.modelData.id)
                            }
                            M3.Button {
                                variant: "tonal"
                                materialIcon: "check"
                                text: "Save label"
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
        M3.TextField {
            id: clientIdField
            Layout.fillWidth: true
            placeholderText: "OAuth client ID"
            text: Gmail.savedClientId
        }
        M3.TextField {
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

    M3.Divider {}
    RowLayout {
        Layout.fillWidth: true
        Layout.margins: Appearance.spacing.m
        StyledText {
            Layout.fillWidth: true
            text: `Poll every ${Gmail.refreshIntervalMinutes} min`
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: Appearance.colors.colSubtext
        }
        M3.Button {
            variant: "tonal"
            materialIcon: "add"
            text: Gmail.signingIn ? "Waiting for Google" : "Add account"
            enabled: !Gmail.signingIn
            onClicked: Gmail.signIn(Gmail.credentialsAvailable ? Gmail.savedClientId : clientIdField.text,
                                    Gmail.credentialsAvailable ? "" : clientSecretField.text)
        }
    }
}
