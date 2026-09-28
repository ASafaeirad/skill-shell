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
import qs.modules.common.m3 as M3

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
                focus: true

                Keys.onPressed: event => {
                    if (event.matches(StandardKey.Undo) && Gmail.undoLatestRemoval())
                        event.accepted = true;
                }

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
                            } else if (operation === "archive" || operation === "trash") {
                                Gmail.removeWithUndo(root.selectedMessage, operation);
                                root.selectedMessage = null;
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
                            M3.IconButton {
                                size: "xsmall"
                                materialIcon: "settings"
                                tooltip: "Accounts"
                                onClicked: root.showAccounts = true
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.leftMargin: Appearance.spacing.m
                            Layout.rightMargin: Appearance.spacing.m
                            Layout.bottomMargin: Appearance.spacing.m
                            spacing: Appearance.spacing.xs

                            M3.Chip {
                                variant: "filter"
                                materialIcon: "all_inbox"
                                text: `All ${Gmail.totalMessages}`
                                selected: root.accountFilter === ""
                                onClicked: root.accountFilter = ""
                            }

                            Repeater {
                                model: Gmail.accounts
                                delegate: M3.Chip {
                                    id: accountDot
                                    required property var modelData
                                    variant: "filter"
                                    dotColor: root.accountColor(accountDot.modelData.color)
                                    selected: root.accountFilter === accountDot.modelData.id
                                    onClicked: root.accountFilter = accountDot.modelData.id
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
                            delegate: ColumnLayout {
                                id: expiredRow
                                required property var modelData
                                Layout.fillWidth: true
                                spacing: 0

                                RowLayout {
                                    Layout.fillWidth: true
                                    Layout.leftMargin: Appearance.spacing.m
                                    Layout.rightMargin: Appearance.spacing.m
                                    Layout.topMargin: Appearance.spacing.xs
                                    Layout.bottomMargin: Appearance.spacing.xs
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
                                    M3.Button {
                                        variant: "text"
                                        text: Gmail.signingIn ? "Waiting for Google" : "Reconnect"
                                        enabled: !Gmail.signingIn
                                        onClicked: Gmail.reconnect(expiredRow.modelData.id)
                                    }
                                }

                                M3.Divider {}
                            }
                        }

                        M3.LinearProgressIndicator {
                            visible: Gmail.syncing && Gmail.messages.length === 0
                            Layout.fillWidth: true
                            indeterminate: true
                            highlightColor: Appearance.colors.colPrimary
                            trackColor: Appearance.colors.colOutlineVariant
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

                        Item {
                            visible: !Gmail.syncing && root.filteredMessages.length === 0 && !root.degraded
                            Layout.fillWidth: true
                            implicitHeight: clearContent.implicitHeight + Appearance.spacing.xxl * 2

                            ColumnLayout {
                                id: clearContent
                                anchors.centerIn: parent
                                spacing: Appearance.spacing.s
                                MaterialSymbol {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: "check_circle"
                                    iconSize: Appearance.font.pixelSize.hugeass
                                    color: Appearance.colors.colSubtext
                                }
                                StyledText {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: "All inboxes clear"
                                    font.pixelSize: Appearance.font.pixelSize.small
                                    color: Appearance.colors.colSubtext
                                }
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
                                        // Archive/trash undo window: the row becomes its own undo
                                        // bar, a line drains along the bottom, then the row folds.
                                        readonly property var removal: Gmail.pendingRemoval(modelData)
                                        property bool folded: false
                                        property real undoProgress: 0
                                        width: rows.width
                                        height: folded ? 0 : Appearance.sizes.barHeight + Appearance.spacing.xxl
                                        opacity: folded ? 0 : 1
                                        clip: true
                                        color: rowHover.hovered
                                               ? Appearance.colors.colSurfaceContainerHigh : "transparent"

                                        // Rows are rebuilt whenever the inbox changes, so derive the
                                        // countdown from the removal's start time, not from creation.
                                        function syncRemoval() {
                                            drainAnimation.stop();
                                            if (!row.removal) {
                                                row.folded = false;
                                                row.undoProgress = 0;
                                                return;
                                            }
                                            const remaining = row.removal.startedAt + Gmail.undoWindowMs - Date.now();
                                            row.folded = remaining <= 0;
                                            if (row.folded)
                                                return;
                                            row.undoProgress = remaining / Gmail.undoWindowMs;
                                            drainAnimation.duration = remaining;
                                            drainAnimation.start();
                                        }
                                        onRemovalChanged: syncRemoval()
                                        Component.onCompleted: syncRemoval()

                                        NumberAnimation {
                                            id: drainAnimation
                                            target: row
                                            property: "undoProgress"
                                            to: 0
                                            onFinished: row.folded = row.removal !== null
                                        }

                                        Behavior on height {
                                            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                                        }
                                        Behavior on opacity {
                                            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                                        }

                                        HoverHandler {
                                            id: rowHover
                                        }

                                        M3.Divider {
                                            anchors.bottom: parent.bottom
                                            width: parent.width
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
                                                        delegate: M3.Chip {
                                                            required property string modelData
                                                            variant: "assist"
                                                            compact: true
                                                            readOnly: true
                                                            text: modelData
                                                            Layout.maximumWidth:
                                                                Appearance.sizes.gmailPopoverWidth / 3.5
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
                                            visible: rowHover.hovered && !row.actionPending && !row.removal
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
                                                    delegate: M3.IconButton {
                                                        id: actionButton
                                                        required property var modelData
                                                        size: "xsmall"
                                                        materialIcon: actionButton.modelData.icon
                                                        tooltip: actionButton.modelData.title
                                                        error: actionButton.modelData.operation === "trash"
                                                        enabled: !Gmail.acting
                                                        onClicked: {
                                                            const operation = actionButton.modelData.operation;
                                                            if (operation === "archive" || operation === "trash")
                                                                Gmail.removeWithUndo(row.modelData, operation);
                                                            else if (operation === "open")
                                                                root.openMessageInBrowser(row.modelData);
                                                            else if (operation === "labels") {
                                                                if (Gmail.fetchLabels(row.modelData.accountId)) {
                                                                    root.labelAnchor = actionButton.mapToItem(
                                                                        surface, actionButton.width / 2,
                                                                        actionButton.height);
                                                                    root.labelMessage = row.modelData;
                                                                }
                                                            } else
                                                                Gmail.messageAction(row.modelData, operation);
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
                                        M3.Snackbar {
                                            anchors.fill: parent
                                            z: 4
                                            visible: row.removal !== null
                                            variant: "two-line"
                                            leadingIcon: row.removal?.operation === "trash" ? "delete" : "archive"
                                            text: row.removal?.operation === "trash" ? "Moved to trash" : "Archived"
                                            supportingText: `${row.modelData.sender} · ${row.modelData.subject}`
                                            actionText: "Undo"
                                            actionTooltip: "Undo (Ctrl+Z)"
                                            progress: row.undoProgress
                                            onActionClicked: Gmail.undoRemoval(row.modelData)
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
                            M3.Button {
                                variant: "tonal"
                                materialIcon: "refresh"
                                text: "Retry now"
                                enabled: !Gmail.syncing
                                onClicked: Gmail.retryNow()
                            }
                        }

                        M3.Divider {}
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
                                M3.Button {
                                    visible: Gmail.actionError.includes("Sign in again")
                                    variant: "filled"
                                    error: true
                                    text: "Sign in"
                                    onClicked: Gmail.reconnect(Gmail.actionAccountId)
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
                            M3.Button {
                                variant: "tonal"
                                materialIcon: "open_in_new"
                                text: "Open Gmail"
                                onClicked: root.openGmail()
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
                M3.Menu {
                    visible: root.labelMessage !== null && !root.showAccounts
                    x: Math.max(Appearance.spacing.m,
                                Math.min(root.labelAnchor.x, parent.width - width - Appearance.spacing.m))
                    y: Math.max(Appearance.spacing.m,
                                Math.min(root.labelAnchor.y, parent.height - height - Appearance.spacing.m))
                    width: Appearance.sizes.gmailPopoverWidth / 2
                    height: Math.min(labelMenu.implicitHeight, Appearance.sizes.barHeight * 6)
                    z: 3

                    // The heading and Cancel stay put so a long label list
                    // scrolls under them rather than pushing Cancel out of reach.
                    ColumnLayout {
                        id: labelMenu
                        anchors.fill: parent
                        anchors.topMargin: Appearance.spacing.s
                        anchors.bottomMargin: Appearance.spacing.s
                        spacing: 0

                        StyledText {
                            Layout.fillWidth: true
                            Layout.leftMargin: Appearance.spacing.m
                            Layout.bottomMargin: Appearance.spacing.xs
                            text: "Add label"
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colOnSurface
                        }
                        StyledText {
                            visible: Gmail.isFetchingLabels(root.labelAccountId)
                                     || Gmail.labelsForAccount(root.labelAccountId).length === 0
                            Layout.fillWidth: true
                            Layout.leftMargin: Appearance.spacing.m
                            Layout.bottomMargin: Appearance.spacing.xs
                            text: Gmail.isFetchingLabels(root.labelAccountId) ? "Loading labels…"
                                  : (Gmail.labelErrorsByAccount[root.labelAccountId] || "No labels available")
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colSubtext
                        }
                        Flickable {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            implicitHeight: labelChoices.implicitHeight
                            contentHeight: labelChoices.implicitHeight
                            clip: true
                            boundsBehavior: Flickable.StopAtBounds

                            ColumnLayout {
                                id: labelChoices
                                width: parent.width
                                spacing: 0
                                Repeater {
                                    model: Gmail.labelsForAccount(root.labelAccountId)
                                    delegate: M3.MenuItem {
                                        id: labelChoice
                                        required property var modelData
                                        Layout.fillWidth: true
                                        density: -3
                                        text: labelChoice.modelData.name
                                        onClicked: {
                                            Gmail.messageAction(root.labelMessage, "label", labelChoice.modelData.id);
                                            root.labelMessage = null;
                                        }
                                    }
                                }
                            }
                        }
                        M3.Divider {}
                        M3.MenuItem {
                            Layout.fillWidth: true
                            density: -3
                            text: "Cancel"
                            onClicked: root.labelMessage = null
                        }
                    }
                }
            }
        }
    }
}
