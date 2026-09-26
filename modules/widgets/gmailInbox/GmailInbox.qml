pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

Panel {
    id: root
    name: "gmailInbox"
    description: "Toggle Gmail inbox"
    hasOpenCloseShortcuts: true

    property string accountFilter: ""
    property bool showAccounts: false
    property var selectedMessage: null
    property var labelMessage: null
    property point labelAnchor: Qt.point(0, 0)
    readonly property string labelAccountId: root.labelMessage?.accountId ?? ""
    onOpenedChanged: {
        Gmail.clearActionError();
        if (opened) {
            Gmail.preloadLabels();
        } else {
            showAccounts = false;
            selectedMessage = null;
            labelMessage = null;
        }
    }

    Connections {
        target: Gmail
        function onCredentialsAvailableChanged() {
            if (root.opened && Gmail.credentialsAvailable)
                Gmail.preloadLabels();
        }
        function onMessageActionCompleted(success, operation, accountId, messageId) {
            if (!success || root.selectedMessage?.id !== messageId
                    || root.selectedMessage?.accountId !== accountId)
                return;
            if (operation === "archive" || operation === "trash") {
                root.selectedMessage = null;
            } else if (operation === "read" || operation === "unread") {
                root.selectedMessage = Object.assign({}, root.selectedMessage, { read: operation === "read" });
            }
        }
    }
    readonly property var filteredMessages: Gmail.messages.filter(message => !root.accountFilter
                                                                             || message.accountId
                                                                             === root.accountFilter).slice(0,
                                                                                                           12)
    readonly property int filteredTotal: root.accountFilter ? (Gmail.accounts.find(account => account.id
                                                                                              === root.accountFilter)
                                                               ?.total ?? 0) : Gmail.totalMessages
    readonly property int unreadTotal: Gmail.accounts.reduce((sum, account) => sum + (account.unread ?? 0), 0)
    readonly property int filteredUnread: root.accountFilter ? (Gmail.accounts.find(account => account.id
                                                                                               === root.accountFilter)
                                                                ?.unread ?? 0) : root.unreadTotal

    // Seconds until the service's next scheduled poll, ticked only while the
    // failure sections that display it are on screen.
    property int retrySeconds: 0
    readonly property bool degraded: Gmail.offline || Gmail.expiredAccounts.length > 0

    function accountColor(key) {
        return Appearance.m3colors[key] ?? Appearance.colors.colPrimary;
    }

    function formatCountdown(seconds) {
        return `${("0" + Math.floor(seconds / 60)).slice(-2)}:${("0" + seconds % 60).slice(-2)}`;
    }

    function messageTime(timestamp) {
        const date = new Date(timestamp);
        const now = new Date();
        if (date.toDateString() === now.toDateString())
            return Qt.formatTime(date, "HH:mm");
        if (now.getTime() - date.getTime() < 6 * 24 * 60 * 60 * 1000)
            return Qt.formatDate(date, "ddd");
        return Qt.formatDate(date, "d MMM");
    }

    function categoryName(category) {
        return category?.startsWith("CATEGORY_") ? category.slice(9).toLowerCase().replace(/^./, letter
                                                                                           => letter.toUpperCase(
                                                                                                  )) : category;
    }

    Timer {
        running: root.opened && root.degraded
        interval: 1000
        repeat: true
        triggeredOnStart: true
        onTriggered: root.retrySeconds = Gmail.nextRetryAt > 0 ? Math.max(0, Math.round((Gmail.nextRetryAt
                                                                                         - Date.now())
                                                                                        / 1000)) : 0
    }

    // Gmail addresses accounts by signed-in position (u/0, u/1, ...), not by
    // address, so map an account id onto its index in the configured list.
    // Unknown or unfiltered ids fall back to the first account.
    function accountIndex(accountId) {
        return Math.max(0, Gmail.accounts.findIndex(account => account.id === accountId));
    }

    function readMessage(message) {
        root.selectedMessage = message;
        root.labelMessage = null;
        Gmail.clearActionError();
        Gmail.readMessage(message);
        if (!message.read)
            Gmail.messageAction(message, "read");
    }

    function openMessageInBrowser(message) {
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
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
            anchorName: "gmail"
            layerNamespace: "quickshell:gmailInbox"
            implicitWidth: Appearance.sizes.gmailPopoverWidth
            // Keep the layer window still while the visible card changes height.
            implicitHeight: Math.max(accountsView.implicitHeight, inboxView.implicitHeight,
                                     readingView.implicitHeight)
            onDismissed: root.close()

            mask: Region {
                item: surface
            }

            Rectangle {
                id: surface
                y: Config.options.bar.bottom ? parent.height - height : 0
                width: parent.width
                implicitHeight: content.implicitHeight
                color: Appearance.colors.colBackgroundSurfaceContainer
                border.color: Appearance.colors.colLayer0Border
                border.width: Appearance.spacing.xxs / 2
                radius: Appearance.rounding.normal
                clip: true

                Behavior on implicitHeight {
                    NumberAnimation {
                        duration: Appearance.animation.elementMoveFast.duration
                        easing.type: Appearance.animation.elementMoveFast.type
                        easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
                    }
                }

                ColumnLayout {
                    id: content
                    width: parent.width
                    spacing: 0

                    GmailAccountsView {
                        id: accountsView
                        visible: root.showAccounts
                        Layout.fillWidth: true
                        onBackRequested: root.showAccounts = false
                    }

                    GmailReadingView {
                        id: readingView
                        visible: !root.showAccounts && root.selectedMessage !== null
                        Layout.fillWidth: true
                        message: root.selectedMessage ?? ({ id: "", sender: "", subject: "", timestamp: 0,
                                                          accountId: "", accountEmail: "", threadId: "" })
                        maximumHeight: (popup.screen?.height ?? Appearance.sizes.barHeight * 12)
                                       - Appearance.sizes.barHeight - Appearance.spacing.xxl
                        onBackRequested: root.selectedMessage = null
                        onBrowserRequested: root.openMessageInBrowser(root.selectedMessage)
                        onActionRequested: (operation, anchor) => {
                            if (operation === "labels") {
                                if (Gmail.fetchLabels(root.selectedMessage.accountId)) {
                                    root.labelAnchor = readingView.mapToItem(surface, anchor.x, anchor.y);
                                    root.labelMessage = root.selectedMessage;
                                }
                            } else {
                                Gmail.messageAction(root.selectedMessage, operation);
                            }
                        }
                    }

                    ColumnLayout {
                        id: inboxView
                        visible: !root.showAccounts && root.selectedMessage === null
                        Layout.fillWidth: true
                        spacing: 0

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.leftMargin: Appearance.spacing.lg
                            Layout.rightMargin: Appearance.spacing.m
                            Layout.topMargin: Appearance.spacing.m
                            Layout.bottomMargin: Appearance.spacing.xs
                            spacing: Appearance.spacing.xs

                            StyledText {
                                Layout.fillWidth: true
                                text: "Inbox"
                                font.pixelSize: Appearance.font.pixelSize.normal
                                font.weight: Font.DemiBold
                                color: Appearance.colors.colOnSurface
                            }
                            MaterialSymbol {
                                text: "settings"
                                iconSize: Appearance.font.pixelSize.large
                                color: Appearance.colors.colSubtext
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.showAccounts = true
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.leftMargin: Appearance.spacing.m
                            Layout.rightMargin: Appearance.spacing.m
                            Layout.bottomMargin: Appearance.spacing.m
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
                                        font.pixelSize: Appearance.font.pixelSize.smallie
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
                            StyledText {
                                visible: root.accountFilter !== ""
                                text: Gmail.accounts.find(account => account.id === root.accountFilter)?.label
                                      ?? ""
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                color: Appearance.colors.colSubtext
                                elide: Text.ElideRight
                                Layout.maximumWidth: Appearance.sizes.gmailPopoverWidth / 4
                            }
                        }

                        // Gmail is unreachable: say the list is cached rather than let it
                        // read as an inbox that emptied itself.
                        Rectangle {
                            visible: Gmail.offline
                            Layout.fillWidth: true
                            implicitHeight: offlineBanner.implicitHeight + Appearance.spacing.m * 2
                            color: Appearance.colors.colErrorContainer

                            RowLayout {
                                id: offlineBanner
                                anchors.fill: parent
                                anchors.margins: Appearance.spacing.m
                                spacing: Appearance.spacing.s

                                MaterialSymbol {
                                    Layout.alignment: Qt.AlignTop
                                    text: "cloud_off"
                                    iconSize: Appearance.font.pixelSize.larger
                                    color: Appearance.colors.colOnErrorContainer
                                }
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: Appearance.spacing.xxs
                                    StyledText {
                                        text: "Can't reach Gmail"
                                        font.pixelSize: Appearance.font.pixelSize.smallie
                                        color: Appearance.colors.colOnErrorContainer
                                    }
                                    StyledText {
                                        Layout.fillWidth: true
                                        text: Gmail.lastSync.getTime() ? `Showing the cached inbox from
${Qt.formatTime(Gmail.lastSync, "hh:mm")}.` : "No cached inbox to show yet."
                                        font.pixelSize: Appearance.font.pixelSize.smaller
                                        color: Appearance.colors.colOnErrorContainer
                                        wrapMode: Text.Wrap
                                    }
                                }
                            }
                        }

                        // One expired account degrades to its own row; the rest keep syncing.
                        Repeater {
                            model: Gmail.expiredAccounts
                            delegate: Rectangle {
                                id: expiredRow
                                required property var modelData
                                Layout.fillWidth: true
                                implicitHeight: expiredLayout.implicitHeight + Appearance.spacing.m * 2
                                color: "transparent"

                                RowLayout {
                                    id: expiredLayout
                                    anchors.fill: parent
                                    anchors.leftMargin: Appearance.spacing.m
                                    anchors.rightMargin: Appearance.spacing.m
                                    spacing: Appearance.spacing.s

                                    Rectangle {
                                        Layout.alignment: Qt.AlignVCenter
                                        implicitWidth: Appearance.spacing.xs
                                        implicitHeight: Appearance.spacing.xs
                                        radius: Appearance.rounding.full
                                        color: root.accountColor(expiredRow.modelData.color)
                                    }
                                    StyledText {
                                        Layout.fillWidth: true
                                        text: `${expiredRow.modelData.label || expiredRow.modelData.email
                                              } — sign-in expired`
                                        font.pixelSize: Appearance.font.pixelSize.smallie
                                        color: Appearance.colors.colOnLayer1
                                        elide: Text.ElideRight
                                    }
                                    StyledText {
                                        text: Gmail.signingIn ? "Waiting for Google" : "Reconnect"
                                        font.pixelSize: Appearance.font.pixelSize.smaller
                                        color: Appearance.colors.colPrimary
                                        MouseArea {
                                            anchors.fill: parent
                                            enabled: !Gmail.signingIn
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: Gmail.reconnect(expiredRow.modelData.id)
                                        }
                                    }
                                }

                                Rectangle {
                                    anchors.bottom: parent.bottom
                                    width: parent.width
                                    height: Appearance.spacing.xxs / 2
                                    color: Appearance.colors.colLayer0Border
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
                            visible: !Gmail.syncing && root.filteredMessages.length === 0 && !root.degraded
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
                            implicitHeight: Math.min(rows.implicitHeight, Appearance.sizes.barHeight * 8)
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
                                        readonly property bool actionPending: Gmail.acting
                                            && Gmail.actionAccountId === modelData.accountId
                                            && Gmail.actionMessageId === modelData.id
                                        width: rows.width
                                        height: Appearance.sizes.barHeight + Appearance.spacing.xxl
                                        color: rowHover.hovered
                                               ? Appearance.colors.colSurfaceContainerHigh : "transparent"

                                        HoverHandler {
                                            id: rowHover
                                        }

                                        Rectangle {
                                            anchors.bottom: parent.bottom
                                            width: parent.width
                                            height: Appearance.spacing.xxs / 2
                                            color: Appearance.colors.colLayer0Border
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            enabled: !row.actionPending
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.readMessage(row.modelData)
                                        }

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: Appearance.spacing.lg
                                            anchors.rightMargin: Appearance.spacing.lg
                                            spacing: Appearance.spacing.s
                                            Rectangle {
                                                Layout.alignment: Qt.AlignVCenter
                                                implicitWidth: Appearance.spacing.s
                                                implicitHeight: implicitWidth
                                                radius: Appearance.rounding.full
                                                color: row.modelData.read ? "transparent" :
                                                                            Appearance.colors.colPrimary
                                            }
                                            Rectangle {
                                                Layout.alignment: Qt.AlignVCenter
                                                implicitWidth: Appearance.spacing.xxl
                                                implicitHeight: implicitWidth
                                                radius: Appearance.rounding.unsharpenmore
                                                color: root.accountColor(row.modelData.accountColor)
                                                StyledText {
                                                    anchors.centerIn: parent
                                                    text: row.modelData.sender.charAt(0).toUpperCase()
                                                    font.pixelSize: Appearance.font.pixelSize.small
                                                    color: Appearance.m3colors.m3onPrimary
                                                }
                                            }
                                            ColumnLayout {
                                                Layout.fillWidth: true
                                                spacing: Appearance.spacing.xxs
                                                StyledText {
                                                    Layout.fillWidth: true
                                                    text: row.modelData.sender
                                                    font.pixelSize: Appearance.font.pixelSize.small
                                                    color: Appearance.colors.colSubtext
                                                    elide: Text.ElideRight
                                                }
                                                StyledText {
                                                    Layout.fillWidth: true
                                                    text: row.modelData.subject
                                                    font.pixelSize: Appearance.font.pixelSize.small
                                                    font.weight: row.modelData.read ? Font.Normal :
                                                                                      Font.DemiBold
                                                    color: row.modelData.read ? Appearance.colors.colOnLayer1 :
                                                                                Appearance.colors.colOnSurface
                                                    elide: Text.ElideRight
                                                }
                                                RowLayout {
                                                    spacing: Appearance.spacing.xs
                                                    Repeater {
                                                        model: [root.categoryName(row.modelData.category), ...(
                                                                row.modelData.labels ?? [])].filter(
                                                            Boolean).slice(0, 2)
                                                        delegate: Rectangle {
                                                            id: tagRect
                                                            required property string modelData
                                                            implicitWidth: Math.min(tag.implicitWidth
                                                                                    + Appearance.spacing.s * 2,
                                                                                    Appearance.sizes.gmailPopoverWidth
                                                                                    / 3.5)
                                                            implicitHeight: tag.implicitHeight
                                                                            + Appearance.spacing.xxs * 2
                                                            radius: Appearance.rounding.full
                                                            color: Appearance.colors.colSurfaceContainerHigh
                                                            StyledText {
                                                                id: tag
                                                                anchors.centerIn: parent
                                                                width: parent.width - Appearance.spacing.s * 2
                                                                text: tagRect.modelData
                                                                font.pixelSize:
                                                                    Appearance.font.pixelSize.smaller
                                                                color: Appearance.colors.colSubtext
                                                                elide: Text.ElideRight
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                            ColumnLayout {
                                                Layout.alignment: Qt.AlignTop
                                                Layout.topMargin: Appearance.spacing.m
                                                spacing: Appearance.spacing.xs
                                                StyledText {
                                                    visible: !rowHover.hovered
                                                    text: root.messageTime(row.modelData.timestamp)
                                                    font.pixelSize: Appearance.font.pixelSize.smallie
                                                    color: Appearance.colors.colSubtext
                                                }
                                                MaterialSymbol {
                                                    visible: !rowHover.hovered && row.modelData.attachment
                                                    Layout.alignment: Qt.AlignRight
                                                    text: "attach_file"
                                                    iconSize: Appearance.font.pixelSize.smaller
                                                    color: Appearance.colors.colSubtext
                                                }
                                            }
                                        }
                                        Rectangle {
                                            visible: rowHover.hovered && !row.actionPending
                                            anchors.right: parent.right
                                            anchors.rightMargin: Appearance.spacing.s
                                            anchors.verticalCenter: parent.verticalCenter
                                            width: actions.implicitWidth + Appearance.spacing.s
                                            height: Appearance.spacing.xxl + Appearance.spacing.xs
                                            z: 2
                                            color: Appearance.colors.colBackgroundSurfaceContainerHigh
                                            Row {
                                                id: actions
                                                anchors.right: parent.right
                                                anchors.verticalCenter: parent.verticalCenter
                                                spacing: Appearance.spacing.xxs
                                                Repeater {
                                                    model: [
                                                        { icon: "archive", operation: "archive", title: "Archive" },
                                                        {
                                                            icon: row.modelData.read ? "mark_email_unread" : "drafts",
                                                            operation: row.modelData.read ? "unread" : "read",
                                                            title: row.modelData.read ? "Mark as unread" : "Mark as read"
                                                        },
                                                        { icon: "label", operation: "labels", title: "Add label" },
                                                        { icon: "delete", operation: "trash", title: "Move to trash" },
                                                        { icon: "open_in_new", operation: "open", title: "Open in Gmail" }
                                                    ]
                                                    delegate: Rectangle {
                                                        id: actionButton
                                                        required property var modelData
                                                        width: Appearance.spacing.xxl + Appearance.spacing.xs
                                                        height: width
                                                        radius: Appearance.rounding.full
                                                        color: actionHover.containsMouse
                                                               ? Appearance.colors.colLayer3Hover : "transparent"
                                                        MaterialSymbol {
                                                            anchors.centerIn: parent
                                                            text: actionButton.modelData.icon
                                                            iconSize: Appearance.font.pixelSize.huge
                                                            color: actionButton.modelData.operation === "trash"
                                                                   ? Appearance.colors.colError : Appearance.colors.colOnLayer2
                                                        }
                                                        MouseArea {
                                                            id: actionHover
                                                            anchors.fill: parent
                                                            hoverEnabled: true
                                                            enabled: !Gmail.acting
                                                            cursorShape: Qt.PointingHandCursor
                                                            onClicked: mouse => {
                                                                const operation = actionButton.modelData.operation;
                                                                if (operation === "open")
                                                                    root.openMessageInBrowser(row.modelData);
                                                                else if (operation === "labels") {
                                                                    if (Gmail.fetchLabels(row.modelData.accountId)) {
                                                                        root.labelAnchor = actionHover.mapToItem(surface, mouse.x, mouse.y);
                                                                        root.labelMessage = row.modelData;
                                                                    }
                                                                } else
                                                                    Gmail.messageAction(row.modelData, operation);
                                                            }
                                                        }
                                                        StyledToolTip {
                                                            extraVisibleCondition: actionHover.containsMouse
                                                            text: actionButton.modelData.title
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                        Item {
                                            id: actionShimmer
                                            anchors.fill: parent
                                            z: 3
                                            visible: row.actionPending
                                            clip: true

                                            Rectangle {
                                                anchors.fill: parent
                                                color: ColorUtils.applyAlpha(Appearance.colors.colSurfaceContainerHigh, 0.25)
                                            }
                                            Rectangle {
                                                id: shimmerBand
                                                width: actionShimmer.width * 0.75
                                                height: actionShimmer.height * 2
                                                anchors.verticalCenter: parent.verticalCenter
                                                rotation: 15
                                                gradient: Gradient {
                                                    orientation: Gradient.Horizontal
                                                    GradientStop { position: 0.0; color: "transparent" }
                                                    GradientStop {
                                                        position: 0.5
                                                        color: ColorUtils.applyAlpha(Appearance.colors.colOnLayer1, 0.16)
                                                    }
                                                    GradientStop { position: 1.0; color: "transparent" }
                                                }
                                                NumberAnimation on x {
                                                    running: row.actionPending
                                                    loops: Animation.Infinite
                                                    from: -shimmerBand.width * 1.5
                                                    to: actionShimmer.width + shimmerBand.width * 0.5
                                                    duration: Appearance.animation.elementMoveEnter.duration * 3
                                                    easing.type: Easing.InOutQuad
                                                }
                                            }
                                            MouseArea {
                                                anchors.fill: parent
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        RowLayout {
                            visible: root.degraded
                            Layout.fillWidth: true
                            Layout.margins: Appearance.spacing.m
                            StyledText {
                                Layout.fillWidth: true
                                text: Gmail.syncing ? "Retrying…" : `Next retry in ${root.formatCountdown(
                                                          root.retrySeconds)}`
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                color: Appearance.colors.colSubtext
                            }
                            Rectangle {
                                implicitWidth: retryLabel.implicitWidth + Appearance.spacing.m * 2
                                implicitHeight: Appearance.spacing.xxl
                                radius: Appearance.rounding.full
                                color: retryHover.containsMouse
                                       ? Appearance.colors.colSurfaceContainerHighestHover :
                                         Appearance.colors.colSurfaceContainerHigh
                                RowLayout {
                                    id: retryLabel
                                    anchors.centerIn: parent
                                    spacing: Appearance.spacing.xs
                                    MaterialSymbol {
                                        text: "refresh"
                                        iconSize: Appearance.font.pixelSize.normal
                                        color: Appearance.colors.colOnLayer2
                                    }
                                    StyledText {
                                        text: "Retry now"
                                        font.pixelSize: Appearance.font.pixelSize.smaller
                                        color: Appearance.colors.colOnLayer2
                                    }
                                }
                                MouseArea {
                                    id: retryHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    enabled: !Gmail.syncing
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Gmail.retryNow()
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: Appearance.spacing.xxs / 2
                            color: Appearance.colors.colLayer0Border
                        }
                        Rectangle {
                            visible: Gmail.actionError.length > 0
                            Layout.fillWidth: true
                            implicitHeight: actionErrorContent.implicitHeight + Appearance.spacing.m * 2
                            color: Appearance.colors.colErrorContainer

                            RowLayout {
                                id: actionErrorContent
                                anchors.fill: parent
                                anchors.margins: Appearance.spacing.m
                                spacing: Appearance.spacing.s
                                MaterialSymbol {
                                    text: "error"
                                    iconSize: Appearance.font.pixelSize.larger
                                    color: Appearance.colors.colOnErrorContainer
                                }
                                StyledText {
                                    Layout.fillWidth: true
                                    Layout.minimumWidth: 0
                                    text: Gmail.actionError
                                    font.pixelSize: Appearance.font.pixelSize.smaller
                                    color: Appearance.colors.colOnErrorContainer
                                    wrapMode: Text.WordWrap
                                }
                                Rectangle {
                                    visible: Gmail.actionError.includes("Sign in again")
                                    implicitWidth: signInLabel.implicitWidth + Appearance.spacing.m * 2
                                    implicitHeight: Appearance.spacing.xxl
                                    radius: Appearance.rounding.full
                                    color: signInHover.containsMouse
                                           ? Appearance.colors.colErrorHover : Appearance.colors.colError
                                    StyledText {
                                        id: signInLabel
                                        anchors.centerIn: parent
                                        text: "Sign in"
                                        font.pixelSize: Appearance.font.pixelSize.smaller
                                        color: Appearance.colors.colOnError
                                    }
                                    MouseArea {
                                        id: signInHover
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: Gmail.reconnect(Gmail.actionAccountId)
                                    }
                                }
                            }
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            Layout.margins: Appearance.spacing.m
                            StyledText {
                                Layout.fillWidth: true
                                text: {
                                    const remaining = Math.max(0, root.filteredTotal
                                                               - root.filteredMessages.length);
                                    const synced = Gmail.lastSync.getTime() ? `Synced ${Qt.formatTime(
                                                                                  Gmail.lastSync, "hh:mm")}` :
                                                                              "Waiting for sync";
                                    return `${synced} · ${root.filteredUnread} unread`;
                                }
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                color: Appearance.colors.colSubtext
                            }
                            Rectangle {
                                implicitWidth: openContent.implicitWidth + Appearance.spacing.m * 2
                                implicitHeight: Appearance.spacing.xxl
                                radius: Appearance.rounding.full
                                color: Appearance.colors.colSurfaceContainerHigh
                                RowLayout {
                                    id: openContent
                                    anchors.centerIn: parent
                                    spacing: Appearance.spacing.xs
                                    MaterialSymbol {
                                        text: "open_in_new"
                                        iconSize: Appearance.font.pixelSize.normal
                                        color: Appearance.colors.colOnLayer1
                                    }
                                    StyledText {
                                        text: "Open Gmail"
                                        font.pixelSize: Appearance.font.pixelSize.smaller
                                        color: Appearance.colors.colOnLayer1
                                    }
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
                MouseArea {
                    anchors.fill: parent
                    visible: root.labelMessage !== null && !root.showAccounts
                    z: 2
                    onClicked: root.labelMessage = null
                }
                Rectangle {
                    visible: root.labelMessage !== null && !root.showAccounts
                    x: Math.max(Appearance.spacing.m,
                                Math.min(root.labelAnchor.x, parent.width - width - Appearance.spacing.m))
                    y: Math.max(Appearance.spacing.m,
                                Math.min(root.labelAnchor.y, parent.height - height - Appearance.spacing.m))
                    width: Appearance.sizes.gmailPopoverWidth / 2
                    height: Math.min(labelChoices.implicitHeight + Appearance.spacing.m * 2,
                                     Appearance.sizes.barHeight * 6)
                    radius: Appearance.rounding.normal
                    color: Appearance.m3colors.m3surfaceContainerHigh
                    border.color: Appearance.colors.colLayer0Border
                    z: 3

                    Flickable {
                        anchors.fill: parent
                        anchors.margins: Appearance.spacing.m
                        contentHeight: labelChoices.implicitHeight
                        clip: true
                        Column {
                            id: labelChoices
                            width: parent.width
                            spacing: Appearance.spacing.xs
                            StyledText {
                                width: parent.width
                                text: "Add label"
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: Appearance.colors.colOnSurface
                            }
                            StyledText {
                                visible: Gmail.isFetchingLabels(root.labelAccountId)
                                         || Gmail.labelsForAccount(root.labelAccountId).length === 0
                                width: parent.width
                                text: Gmail.isFetchingLabels(root.labelAccountId) ? "Loading labels…"
                                      : (Gmail.labelErrorsByAccount[root.labelAccountId] || "No labels available")
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                color: Appearance.colors.colSubtext
                            }
                            Column {
                                width: parent.width
                                spacing: Appearance.spacing.xxs
                                Repeater {
                                    model: Gmail.labelsForAccount(root.labelAccountId)
                                    delegate: Rectangle {
                                        id: labelChoice
                                        required property var modelData
                                        width: labelChoices.width
                                        height: Appearance.spacing.xl
                                        radius: Appearance.rounding.unsharpenmore
                                        color: labelHover.containsMouse
                                               ? Appearance.colors.colLayer3Hover : "transparent"
                                        StyledText {
                                            anchors.left: parent.left
                                            anchors.leftMargin: Appearance.spacing.s
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: labelChoice.modelData.name
                                            font.pixelSize: Appearance.font.pixelSize.smaller
                                            color: Appearance.colors.colOnLayer2
                                        }
                                        MouseArea {
                                            id: labelHover
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                Gmail.messageAction(root.labelMessage, "label", labelChoice.modelData.id);
                                                root.labelMessage = null;
                                            }
                                        }
                                    }
                                }
                            }
                            StyledText {
                                width: parent.width
                                text: "Cancel"
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                color: Appearance.colors.colPrimary
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.labelMessage = null
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
