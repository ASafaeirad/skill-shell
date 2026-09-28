pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.m3 as M3

ColumnLayout {
    id: root

    required property var message
    required property real maximumHeight
    property var detail: Gmail.readDetail?.id === message.id ? Gmail.readDetail : null
    property var account: Gmail.accounts.find(item => item.id === message.accountId)
    signal backRequested()
    signal browserRequested()
    signal actionRequested(string operation, point anchor)

    spacing: 0

    function attachmentSize(bytes) {
        if (bytes < 1024)
            return `${bytes} B`;
        if (bytes < 1024 * 1024)
            return `${Math.round(bytes / 1024)} KB`;
        return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
    }

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
            text: root.account?.label || root.message.accountEmail
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: Appearance.colors.colSubtext
            elide: Text.ElideRight
        }
        Repeater {
            model: [
                { icon: "archive", operation: "archive", title: "Archive" },
                { icon: "label", operation: "labels", title: "Add label" },
                { icon: "delete", operation: "trash", title: "Move to trash" },
                { icon: "open_in_new", operation: "open", title: "Open in Gmail" }
            ]
            delegate: M3.IconButton {
                id: headerAction
                required property var modelData
                size: "xsmall"
                materialIcon: headerAction.modelData.icon
                tooltip: headerAction.modelData.title
                error: headerAction.modelData.operation === "trash"
                enabled: headerAction.modelData.operation === "open" || !Gmail.acting
                onClicked: {
                    if (headerAction.modelData.operation === "open")
                        root.browserRequested();
                    else
                        root.actionRequested(headerAction.modelData.operation,
                                             headerAction.mapToItem(root, headerAction.width / 2,
                                                                    headerAction.height));
                }
            }
        }
    }

    M3.Divider {}

    Flickable {
        id: scroll
        Layout.fillWidth: true
        implicitHeight: Math.min(readContent.implicitHeight + Appearance.spacing.lg * 2,
                                 Math.max(Appearance.sizes.barHeight * 2,
                                          root.maximumHeight - Appearance.sizes.barHeight * 2))
        contentHeight: readContent.implicitHeight + Appearance.spacing.lg * 2
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: readContent
            x: Appearance.spacing.lg
            y: Appearance.spacing.lg
            width: scroll.width - Appearance.spacing.lg * 2
            spacing: Appearance.spacing.m

            StyledText {
                Layout.fillWidth: true
                text: root.detail?.subject ?? root.message.subject
                textFormat: Text.PlainText
                wrapMode: Text.WordWrap
                font.pixelSize: Appearance.font.pixelSize.large
                color: Appearance.colors.colOnSurface
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacing.m

                Rectangle {
                    implicitWidth: Appearance.spacing.xxl + Appearance.spacing.s
                    implicitHeight: implicitWidth
                    radius: Appearance.rounding.full
                    color: Appearance.colors.colPrimaryContainer
                    border.width: Appearance.spacing.xxs
                    border.color: Appearance.m3colors[root.account?.color ?? "term6"]
                    StyledText {
                        anchors.centerIn: parent
                        text: (root.detail?.sender ?? root.message.sender).charAt(0).toUpperCase()
                        font.pixelSize: Appearance.font.pixelSize.smallie
                        color: Appearance.colors.colOnPrimaryContainer
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    StyledText {
                        Layout.fillWidth: true
                        text: root.detail?.sender ?? root.message.sender
                        textFormat: Text.PlainText
                        font.pixelSize: Appearance.font.pixelSize.smallie
                        color: Appearance.colors.colOnSurface
                        elide: Text.ElideRight
                    }
                    StyledText {
                        Layout.fillWidth: true
                        text: `to ${root.detail?.recipient || root.message.accountEmail} · ${Qt.formatDateTime(
                                  new Date(root.detail?.timestamp ?? root.message.timestamp), "d MMM, HH:mm")}`
                        textFormat: Text.PlainText
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colSubtext
                        elide: Text.ElideRight
                    }
                }
            }

            StyledText {
                visible: !root.detail
                Layout.fillWidth: true
                text: Gmail.readError || "Loading message…"
                font.pixelSize: Appearance.font.pixelSize.smallie
                color: Gmail.readError ? Appearance.colors.colError : Appearance.colors.colSubtext
                wrapMode: Text.WordWrap
            }

            StyledText {
                visible: Gmail.actionError.length > 0
                Layout.fillWidth: true
                text: Gmail.actionError
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colError
                wrapMode: Text.WordWrap
            }

            StyledText {
                visible: !!root.detail
                Layout.fillWidth: true
                text: root.detail?.body || "No message text"
                textFormat: Text.PlainText
                wrapMode: Text.WrapAnywhere
                font.pixelSize: Appearance.font.pixelSize.smallie
                color: Appearance.colors.colOnLayer1
            }

            Repeater {
                model: root.detail?.attachments ?? []
                delegate: M3.Card {
                    id: attachmentChip
                    required property var modelData
                    Layout.fillWidth: true
                    padding: Appearance.spacing.m
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Appearance.spacing.s
                        MaterialSymbol {
                            text: "description"
                            iconSize: Appearance.font.pixelSize.large
                            color: Appearance.colors.colOnLayer2
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            StyledText {
                                Layout.fillWidth: true
                                text: attachmentChip.modelData.filename
                                textFormat: Text.PlainText
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                color: Appearance.colors.colOnSurface
                                elide: Text.ElideRight
                            }
                            StyledText {
                                text: root.attachmentSize(attachmentChip.modelData.size)
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                color: Appearance.colors.colSubtext
                            }
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacing.s

                M3.Button {
                    variant: "filled"
                    materialIcon: "reply"
                    text: "Reply in Gmail"
                    onClicked: root.browserRequested()
                }

                M3.Button {
                    variant: "tonal"
                    materialIcon: root.message.read ? "mark_email_unread" : "drafts"
                    text: root.message.read ? "Mark unread" : "Mark read"
                    enabled: !Gmail.acting
                    onClicked: root.actionRequested(root.message.read ? "unread" : "read", Qt.point(0, 0))
                }
            }
        }
    }
}
