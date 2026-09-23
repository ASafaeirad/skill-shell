pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets

Panel {
    id: root
    name: "gmailInbox"
    description: "Toggle Gmail inbox"
    hasOpenCloseShortcuts: true

    property string accountFilter: ""
    readonly property var filteredMessages: Gmail.messages.filter(message => !root.accountFilter
                                                                             || message.accountId
                                                                             === root.accountFilter).slice(0,
                                                                                                           12)
    readonly property int filteredTotal: root.accountFilter ? (Gmail.accounts.find(account => account.id
                                                                                              === root.accountFilter)
                                                               ?.total ?? 0) : Gmail.totalMessages

    function accountColor(key) {
        return Appearance.m3colors[key] ?? Appearance.colors.colPrimary;
    }

    // Gmail addresses accounts by signed-in position (u/0, u/1, ...), not by
    // address, so map an account id onto its index in the configured list.
    // Unknown or unfiltered ids fall back to the first account.
    function accountIndex(accountId) {
        return Math.max(0, Gmail.accounts.findIndex(account => account.id === accountId));
    }

    function openMessage(message) {
        const index = root.accountIndex(message.accountId);
        const thread = encodeURIComponent(message.threadId);
        Qt.openUrlExternally(`https://mail.google.com/mail/u/${index}/#all/${thread}`);
        root.close();
    }

    function openGmail() {
        const index = root.accountIndex(root.accountFilter);
        Qt.openUrlExternally(`https://mail.google.com/mail/u/${index}/`);
        root.close();
    }

    Loader {
        active: root.opened && Gmail.visible
        sourceComponent: BarAnchoredPopover {
            id: popup
            visible: true
            anchorName: "gmail"
            layerNamespace: "quickshell:gmailInbox"
            implicitWidth: Appearance.sizes.gmailPopoverWidth
            implicitHeight: surface.implicitHeight
            onDismissed: root.close()

            mask: Region {
                item: surface
            }

            Rectangle {
                id: surface
                width: parent.width
                implicitHeight: content.implicitHeight
                color: Appearance.colors.colBackgroundSurfaceContainer
                border.color: Appearance.colors.colLayer0Border
                border.width: Appearance.spacing.xxs / 2
                radius: Appearance.rounding.normal
                clip: true

                ColumnLayout {
                    id: content
                    width: parent.width
                    spacing: 0

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.margins: Appearance.spacing.m
                        spacing: Appearance.spacing.xs

                        Rectangle {
                            implicitWidth: allFilter.implicitWidth + Appearance.spacing.m * 2
                            implicitHeight: Appearance.spacing.xxl
                            radius: Appearance.rounding.full
                            color: root.accountFilter === "" ? Appearance.colors.colPrimaryContainer :
                                                               Appearance.colors.colSurfaceContainerHigh

                            RowLayout {
                                id: allFilter
                                anchors.centerIn: parent
                                spacing: Appearance.spacing.xs
                                MaterialSymbol {
                                    text: "all_inbox"
                                    iconSize: Appearance.font.pixelSize.normal
                                    color: Appearance.colors.colOnPrimaryContainer
                                }
                                StyledText {
                                    text: `All ${Gmail.totalMessages}`
                                    font.pixelSize: Appearance.font.pixelSize.smaller
                                    color: Appearance.colors.colOnPrimaryContainer
                                }
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.accountFilter = ""
                            }
                        }

                        Repeater {
                            model: Gmail.accounts
                            delegate: Rectangle {
                                id: accountDot
                                required property var modelData
                                implicitWidth: Appearance.spacing.xxl
                                implicitHeight: Appearance.spacing.xxl
                                radius: Appearance.rounding.full
                                color: root.accountFilter === accountDot.modelData.id
                                       ? Appearance.colors.colSurfaceContainerHigh : "transparent"
                                Rectangle {
                                    anchors.centerIn: parent
                                    width: Appearance.spacing.m
                                    height: width
                                    radius: Appearance.rounding.full
                                    color: root.accountColor(accountDot.modelData.color)
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.accountFilter = accountDot.modelData.id
                                }
                            }
                        }
                        Item {
                            Layout.fillWidth: true
                        }
                        MaterialSymbol {
                            text: "close"
                            iconSize: Appearance.font.pixelSize.large
                            color: Appearance.colors.colSubtext
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.close()
                            }
                        }
                    }

                    Rectangle {
                        visible: Gmail.syncing && Gmail.messages.length === 0
                        Layout.fillWidth: true
                        implicitHeight: Appearance.spacing.xxs
                        color: Appearance.colors.colOutlineVariant
                        Rectangle {
                            width: parent.width / 2
                            height: parent.height
                            color: Appearance.colors.colPrimary
                            SequentialAnimation on x {
                                running: Gmail.syncing && Gmail.messages.length === 0
                                loops: Animation.Infinite
                                NumberAnimation {
                                    to: Appearance.sizes.gmailPopoverWidth / 2
                                    duration: Appearance.animation.elementMove.duration
                                }
                                NumberAnimation {
                                    to: 0
                                    duration: Appearance.animation.elementMove.duration
                                }
                            }
                        }
                    }

                    ColumnLayout {
                        visible: Gmail.syncing && Gmail.messages.length === 0
                        Layout.fillWidth: true
                        Layout.margins: Appearance.spacing.lg
                        spacing: Appearance.spacing.m
                        Repeater {
                            model: 3
                            delegate: RowLayout {
                                Layout.fillWidth: true
                                spacing: Appearance.spacing.m
                                Rectangle {
                                    width: Appearance.spacing.xxl
                                    height: width
                                    radius: Appearance.rounding.full
                                    color: Appearance.colors.colSurfaceContainerHighest
                                }
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: Appearance.spacing.xs
                                    Rectangle {
                                        width: parent.width / 2
                                        height: Appearance.spacing.s
                                        radius: Appearance.rounding.full
                                        color: Appearance.colors.colSurfaceContainerHighest
                                    }
                                    Rectangle {
                                        width: parent.width * 4 / 5
                                        height: Appearance.spacing.s
                                        radius: Appearance.rounding.full
                                        color: Appearance.colors.colSurfaceContainerHigh
                                    }
                                }
                            }
                        }
                    }

                    ColumnLayout {
                        visible: !Gmail.syncing && root.filteredMessages.length === 0
                        Layout.fillWidth: true
                        Layout.margins: Appearance.spacing.xxl
                        spacing: Appearance.spacing.s
                        MaterialSymbol {
                            Layout.alignment: Qt.AlignHCenter
                            text: "check_circle"
                            iconSize: Appearance.font.pixelSize.hugeass
                            color: Appearance.m3colors.m3success
                        }
                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            text: "All inboxes clear"
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colOnSurface
                        }
                    }

                    Flickable {
                        visible: root.filteredMessages.length > 0
                        Layout.fillWidth: true
                        implicitHeight: Math.min(rows.implicitHeight, Appearance.sizes.barHeight * 7)
                        contentHeight: rows.implicitHeight
                        clip: true

                        Column {
                            id: rows
                            width: parent.width
                            Repeater {
                                model: root.filteredMessages
                                delegate: Rectangle {
                                    id: row
                                    required property var modelData
                                    width: rows.width
                                    height: Appearance.sizes.barHeight + Appearance.spacing.s
                                    color: hover.containsMouse ? Appearance.colors.colSurfaceContainerHigh :
                                                                 "transparent"
                                    opacity: modelData.read ? 0.7 : 1

                                    MouseArea {
                                        id: hover
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.openMessage(row.modelData)
                                    }

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: Appearance.spacing.lg
                                        anchors.rightMargin: Appearance.spacing.lg
                                        spacing: Appearance.spacing.m
                                        Rectangle {
                                            Layout.alignment: Qt.AlignVCenter
                                            implicitWidth: Appearance.spacing.xxl
                                            implicitHeight: implicitWidth
                                            radius: Appearance.rounding.unsharpenmore
                                            color: root.accountColor(row.modelData.accountColor)
                                            StyledText {
                                                anchors.centerIn: parent
                                                text: row.modelData.sender.charAt(0).toUpperCase()
                                                font.pixelSize: Appearance.font.pixelSize.smaller
                                                color: Appearance.m3colors.m3onPrimary
                                            }
                                        }
                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: Appearance.spacing.xxs
                                            RowLayout {
                                                Layout.fillWidth: true
                                                StyledText {
                                                    text: row.modelData.sender
                                                    font.pixelSize: Appearance.font.pixelSize.smallie
                                                    color: Appearance.colors.colOnSurface
                                                    elide: Text.ElideRight
                                                    Layout.maximumWidth: Appearance.sizes.gmailPopoverWidth
                                                                         / 3
                                                }
                                                StyledText {
                                                    Layout.fillWidth: true
                                                    text: row.modelData.subject
                                                    font.pixelSize: Appearance.font.pixelSize.smaller
                                                    color: Appearance.colors.colOnLayer1
                                                    elide: Text.ElideRight
                                                }
                                            }
                                            RowLayout {
                                                spacing: Appearance.spacing.xs
                                                Repeater {
                                                    model: [row.modelData.category, ...(row.modelData.labels
                                                                                        ?? [])].filter(
                                                        Boolean).slice(0, 3)
                                                    delegate: Rectangle {
                                                        id: tagRect
                                                        required property string modelData
                                                        implicitWidth: tag.implicitWidth
                                                                       + Appearance.spacing.s * 2
                                                        implicitHeight: tag.implicitHeight
                                                                        + Appearance.spacing.xxs * 2
                                                        radius: Appearance.rounding.full
                                                        color: Appearance.colors.colPrimaryContainer
                                                        StyledText {
                                                            id: tag
                                                            anchors.centerIn: parent
                                                            text: tagRect.modelData
                                                            font.pixelSize: Appearance.font.pixelSize.smallest
                                                            color: Appearance.colors.colOnPrimaryContainer
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                        ColumnLayout {
                                            Layout.alignment: Qt.AlignVCenter
                                            StyledText {
                                                visible: !hover.containsMouse
                                                text: Qt.formatDateTime(new Date(row.modelData.timestamp),
                                                                        "ddd hh:mm")
                                                font.pixelSize: Appearance.font.pixelSize.smaller
                                                color: Appearance.colors.colSubtext
                                            }
                                            MaterialSymbol {
                                                visible: !hover.containsMouse && row.modelData.attachment
                                                Layout.alignment: Qt.AlignRight
                                                text: "attach_file"
                                                iconSize: Appearance.font.pixelSize.smaller
                                                color: Appearance.colors.colSubtext
                                            }
                                            MaterialSymbol {
                                                visible: hover.containsMouse
                                                text: "open_in_new"
                                                iconSize: Appearance.font.pixelSize.large
                                                color: Appearance.colors.colOnLayer1
                                            }
                                        }
                                    }
                                }
                            }
                        }
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
                            text: {
                                const remaining = Math.max(0, root.filteredTotal - root.filteredMessages.length);
                                const synced = Gmail.lastSync.getTime()
                                    ? `Synced ${Qt.formatTime(Gmail.lastSync, "hh:mm")}`
                                    : "Waiting for sync";
                                return `${remaining} more · ${synced}`;
                            }
                            font.pixelSize: Appearance.font.pixelSize.smallest
                            color: Appearance.colors.colSubtext
                        }
                        Rectangle {
                            implicitWidth: openLabel.implicitWidth + Appearance.spacing.m * 2
                            implicitHeight: Appearance.spacing.xxl
                            radius: Appearance.rounding.full
                            color: Appearance.colors.colSurfaceContainerHigh
                            StyledText {
                                id: openLabel
                                anchors.centerIn: parent
                                text: "Open Gmail ↗"
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                color: Appearance.colors.colOnLayer1
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.openGmail()
                            }
                        }
                    }
                }
            }
        }
    }
}
