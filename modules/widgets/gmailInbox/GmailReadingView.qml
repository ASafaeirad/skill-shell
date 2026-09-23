pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

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
            delegate: Rectangle {
                id: headerAction
                required property var modelData
                implicitWidth: Appearance.spacing.xxl
                implicitHeight: implicitWidth
                radius: Appearance.rounding.full
                color: actionMouse.containsMouse ? Appearance.colors.colLayer3Hover : "transparent"
                MaterialSymbol {
                    anchors.centerIn: parent
                    text: headerAction.modelData.icon
                    iconSize: Appearance.font.pixelSize.large
                    color: headerAction.modelData.operation === "trash"
                           ? Appearance.colors.colError : Appearance.colors.colOnLayer2
                }
                MouseArea {
                    id: actionMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: headerAction.modelData.operation === "open" || !Gmail.acting
                    cursorShape: Qt.PointingHandCursor
                    onClicked: mouse => {
                        if (headerAction.modelData.operation === "open")
                            root.browserRequested();
                        else
                            root.actionRequested(headerAction.modelData.operation,
                                                 actionMouse.mapToItem(root, mouse.x, mouse.y));
                    }
                }
                StyledToolTip {
                    extraVisibleCondition: actionMouse.containsMouse
                    text: headerAction.modelData.title
                }
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: Appearance.spacing.xxs / 2
        color: Appearance.colors.colLayer0Border
    }

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
                delegate: Rectangle {
                    id: attachmentChip
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: attachmentRow.implicitHeight + Appearance.spacing.m * 2
                    radius: Appearance.rounding.small
                    color: Appearance.colors.colSurfaceContainerHigh
                    RowLayout {
                        id: attachmentRow
                        anchors.fill: parent
                        anchors.margins: Appearance.spacing.m
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

                Rectangle {
                    implicitWidth: replyRow.implicitWidth + Appearance.spacing.m * 2
                    implicitHeight: Appearance.spacing.xxl + Appearance.spacing.s
                    radius: Appearance.rounding.full
                    color: Appearance.colors.colPrimary
                    RowLayout {
                        id: replyRow
                        anchors.centerIn: parent
                        spacing: Appearance.spacing.xs
                        MaterialSymbol {
                            text: "reply"
                            iconSize: Appearance.font.pixelSize.normal
                            color: Appearance.colors.colOnPrimary
                        }
                        StyledText {
                            text: "Reply in Gmail"
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colOnPrimary
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.browserRequested()
                    }
                }

                Rectangle {
                    implicitWidth: readActionRow.implicitWidth + Appearance.spacing.m * 2
                    implicitHeight: Appearance.spacing.xxl + Appearance.spacing.s
                    radius: Appearance.rounding.full
                    color: Appearance.colors.colSurfaceContainerHigh
                    RowLayout {
                        id: readActionRow
                        anchors.centerIn: parent
                        spacing: Appearance.spacing.xs
                        MaterialSymbol {
                            text: root.message.read ? "mark_email_unread" : "drafts"
                            iconSize: Appearance.font.pixelSize.normal
                            color: Appearance.colors.colOnLayer2
                        }
                        StyledText {
                            text: root.message.read ? "Mark unread" : "Mark read"
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colOnLayer2
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        enabled: !Gmail.acting
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.actionRequested(root.message.read ? "unread" : "read", Qt.point(0, 0))
                    }
                }
            }
        }
    }
}
