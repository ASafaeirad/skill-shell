pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common
import qs.modules.common.functions

Singleton {
    id: root

    // Helper exit codes. Anything else is an unexpected failure.
    readonly property int exitExpired: 2
    readonly property int exitNetwork: 3
    // Repeated failures double the poll interval up to this ceiling.
    readonly property int maxBackoffMs: 30 * 60000
    readonly property int maxFailureStreak: 8
    // More new messages than this collapse into one summary notification.
    readonly property int notificationBurstLimit: 3

    readonly property var options: Config.options?.gmail
    readonly property bool enabled: options?.enable ?? false
    readonly property int refreshIntervalMinutes: Math.max(1, options?.refreshIntervalMinutes ?? 5)
    readonly property bool notifyOnNewMail: options?.notifyOnNewMail ?? false
    readonly property var configuredAccounts: options?.accounts ?? []
    readonly property var accountColorKeys: ["term6", "term2", "term3", "term4", "term5", "term1"]
    readonly property var keyring: KeyringStorage.keyringData?.gmail ?? null
    readonly property bool credentialsAvailable: KeyringStorage.loaded
        && (keyring?.clientId?.length ?? 0) > 0
        && (keyring?.clientSecret?.length ?? 0) > 0
    readonly property bool hasEnabledAccounts: configuredAccounts.some(account => account.enabled !== false)
    readonly property bool visible: enabled && hasEnabledAccounts
    readonly property bool syncing: syncProcess.running
    readonly property bool signingIn: loginProcess.running
    readonly property bool acting: actionProcess.running
    readonly property bool reading: readProcess.running
    property var readDetail: null
    property string readError: ""
    property var requestedRead: null
    property var activeRead: null
    property var labelsByAccount: ({})
    property var labelErrorsByAccount: ({})
    property var pendingLabelAccounts: []
    property string activeLabelAccountId: ""
    property string actionError: ""
    property string actionAccountId: ""
    property string actionMessageId: ""
    property string actionOperation: ""
    signal messageActionCompleted(bool success, string operation, string accountId, string messageId)
    property bool refreshAfterAction: false
    readonly property string savedClientId: keyring?.clientId ?? ""
    readonly property bool hasSavedClientSecret: (keyring?.clientSecret?.length ?? 0) > 0

    property var syncedAccounts: []
    // Last good result per account id, mirrored to disk so the popover can show a
    // cached inbox before — and instead of — the first successful poll:
    //   inboxCache[id] = { messages, historyId, unread, total, seenIds, syncedAt }
    property var inboxCache: ({})
    property date lastSync: new Date(0)
    property var pendingAccount: null
    // Set while a Reconnect is in flight so the finished sign-in can be matched
    // against the account the user asked to restore.
    property string reconnectAccountId: ""
    property string lastOutcome: credentialsAvailable ? "idle" : "signin"
    property string statusMessage: credentialsAvailable ? "" : "Sign in to Gmail"
    // Gmail was unreachable on the last attempt; the panel is serving the cache.
    property bool offline: false
    property int failureStreak: 0
    // The first successful poll in each shell process seeds notification state.
    // Persisted cache entries still restore the inbox, but never make startup noisy.
    property bool hasSuccessfulSyncThisRun: false
    // Epoch milliseconds of the next scheduled poll, or 0 when polling is off.
    property real nextRetryAt: 0

    readonly property int retryDelayMs: Math.min(root.refreshIntervalMinutes * 60000
                                                 * Math.pow(2, Math.max(0, root.failureStreak - 1)),
                                                 root.maxBackoffMs)

    readonly property var accounts: {
        const syncedById = {};
        for (const synced of root.syncedAccounts)
            syncedById[synced.id] = synced;
        return root.configuredAccounts
            .filter(account => account.enabled !== false)
            .map(account => {
                const synced = syncedById[account.id];
                const cached = root.inboxCache[account.id];
                // A failed account keeps showing its last good inbox; only a clean
                // result replaces the cached messages and counts.
                const good = synced && !synced.error ? synced : cached;
                return Object.assign({}, account, {
                    unread: good?.unread ?? null,
                    error: synced?.error ?? null,
                    messages: good?.messages ?? [],
                    total: good?.total ?? 0,
                    cachedAt: cached?.syncedAt ?? 0
                });
            });
    }

    readonly property var expiredAccounts: root.accounts.filter(account => account.error === "expired")

    readonly property var messages: {
        let combined = [];
        for (const account of root.accounts) {
            combined = combined.concat((account.messages ?? []).map(message => Object.assign({}, message, {
                accountId: account.id,
                accountEmail: account.email,
                accountColor: account.color
            })));
        }
        return combined.sort((a, b) => b.timestamp - a.timestamp);
    }
    readonly property int totalMessages: root.accounts.reduce((sum, account) => sum + (account.total ?? 0), 0)

    function saveCredentials(clientId, clientSecret) {
        if (!KeyringStorage.loaded) {
            root.lastOutcome = "signin";
            root.statusMessage = "Unlock the system keyring before saving Gmail credentials";
            return false;
        }
        const trimmedClientId = clientId.trim();
        const secret = clientSecret.length > 0 ? clientSecret : (root.keyring?.clientSecret ?? "");
        if (trimmedClientId.length === 0 || secret.length === 0) {
            root.lastOutcome = "invalid";
            root.statusMessage = "Enter the OAuth client ID and secret";
            return false;
        }
        KeyringStorage.setNestedFields([
            { path: ["gmail", "clientId"], value: trimmedClientId },
            { path: ["gmail", "clientSecret"], value: secret }
        ]);
        root.lastOutcome = "saved";
        root.statusMessage = "OAuth credentials saved in the keyring";
        return true;
    }

    function signIn(clientId, clientSecret) {
        if (root.signingIn)
            return;
        if (!root.saveCredentials(clientId, clientSecret))
            return;
        root.reconnectAccountId = "";
        root.startLogin();
    }

    // Rerun the browser sign-in for one expired account, reusing the stored OAuth
    // client. Every other account is left alone.
    function reconnect(accountId) {
        if (root.signingIn)
            return;
        root.clearActionError();
        if (!root.credentialsAvailable) {
            root.lastOutcome = "signin";
            root.statusMessage = "Add the OAuth client in Settings > Gmail first";
            return;
        }
        root.reconnectAccountId = accountId;
        root.startLogin();
    }

    function startLogin() {
        root.clearActionError();
        root.lastOutcome = "signin";
        root.statusMessage = "Complete sign-in in your browser";
        root.startProcess(loginProcess, {
            clientId: root.keyring.clientId,
            clientSecret: root.keyring.clientSecret
        });
    }

    function retryNow() {
        pollTimer.stop();
        root.sync();
    }

    function clearActionError() {
        root.actionError = "";
    }

    function messageAction(message, operation, labelId) {
        if (root.acting || !root.credentialsAvailable)
            return false;
        const refreshToken = root.keyring?.refreshTokens?.[message.accountId] ?? "";
        if (!refreshToken)
            return false;
        root.actionError = "";
        root.actionAccountId = message.accountId;
        root.actionMessageId = message.id;
        root.actionOperation = operation;
        root.startProcess(actionProcess, {
            clientId: root.keyring.clientId,
            clientSecret: root.keyring.clientSecret,
            refreshToken: refreshToken,
            operation: operation,
            messageId: message.id,
            labelId: labelId ?? ""
        });
        return true;
    }

    function readMessage(message) {
        root.requestedRead = message;
        root.readDetail = null;
        root.readError = "";
        if (!root.reading)
            root.startRead();
    }

    function startRead() {
        const message = root.requestedRead;
        if (!message)
            return;
        const refreshToken = root.keyring?.refreshTokens?.[message.accountId] ?? "";
        if (!root.credentialsAvailable || !refreshToken) {
            root.readError = "Sign in again to read this message";
            return;
        }
        root.activeRead = message;
        root.startProcess(readProcess, {
            clientId: root.keyring.clientId,
            clientSecret: root.keyring.clientSecret,
            refreshToken: refreshToken,
            messageId: message.id
        });
    }

    function finishRead(exitCode) {
        const active = root.activeRead;
        root.activeRead = null;
        if (active?.id !== root.requestedRead?.id
                || active?.accountId !== root.requestedRead?.accountId) {
            Qt.callLater(() => root.startRead());
            return;
        }
        const detail = root.parseOutput(readOutput.text);
        if (exitCode === 0 && detail?.id === active.id) {
            root.readDetail = detail;
            root.readError = "";
        } else {
            root.readError = exitCode === root.exitExpired
                ? "Sign in again to read this message" : "Could not load this message";
        }
    }

    function labelsForAccount(accountId) {
        return root.labelsByAccount[accountId] ?? [];
    }

    function isFetchingLabels(accountId) {
        return root.activeLabelAccountId === accountId || root.pendingLabelAccounts.includes(accountId);
    }

    function preloadLabels() {
        for (const account of root.accounts)
            root.fetchLabels(account.id);
    }

    function fetchLabels(accountId) {
        if (!root.credentialsAvailable)
            return false;
        const refreshToken = root.keyring?.refreshTokens?.[accountId] ?? "";
        if (!refreshToken)
            return false;
        if (Object.prototype.hasOwnProperty.call(root.labelsByAccount, accountId)
                || root.isFetchingLabels(accountId))
            return true;
        const errors = Object.assign({}, root.labelErrorsByAccount);
        delete errors[accountId];
        root.labelErrorsByAccount = errors;
        root.pendingLabelAccounts = root.pendingLabelAccounts.concat(accountId);
        root.startNextLabelFetch();
        return true;
    }

    function startNextLabelFetch() {
        if (labelProcess.running || root.activeLabelAccountId || root.pendingLabelAccounts.length === 0)
            return;
        const accountId = root.pendingLabelAccounts[0];
        root.pendingLabelAccounts = root.pendingLabelAccounts.slice(1);
        const refreshToken = root.keyring?.refreshTokens?.[accountId] ?? "";
        if (!root.credentialsAvailable || !refreshToken) {
            root.startNextLabelFetch();
            return;
        }
        root.activeLabelAccountId = accountId;
        root.startProcess(labelProcess, {
            clientId: root.keyring.clientId,
            clientSecret: root.keyring.clientSecret,
            refreshToken: refreshToken,
            operation: "labels"
        });
    }

    function finishLabelFetch(exitCode) {
        const accountId = root.activeLabelAccountId;
        const response = root.parseOutput(labelOutput.text);
        if (exitCode === 0 && Array.isArray(response?.labels)) {
            root.labelsByAccount = Object.assign({}, root.labelsByAccount, { [accountId]: response.labels });
        } else {
            root.labelErrorsByAccount = Object.assign({}, root.labelErrorsByAccount, {
                [accountId]: exitCode === root.exitExpired
                    ? "Sign in again to load labels" : "Could not load labels"
            });
        }
        root.activeLabelAccountId = "";
        Qt.callLater(() => root.startNextLabelFetch());
    }

    function finishAction(exitCode) {
        if (exitCode !== 0) {
            root.actionError = exitCode === root.exitExpired
                ? "Sign in again to allow mail actions"
                : "Could not update this message";
            root.statusMessage = root.actionError;
            root.messageActionCompleted(false, root.actionOperation, root.actionAccountId, root.actionMessageId);
            return;
        }
        root.actionError = "";
        root.messageActionCompleted(true, root.actionOperation, root.actionAccountId, root.actionMessageId);
        if (root.syncing)
            root.refreshAfterAction = true;
        else
            root.sync();
    }

    function sync() {
        if (root.syncing)
            return;
        if (!root.enabled || !root.hasEnabledAccounts) {
            root.schedulePoll();
            return;
        }
        if (!root.credentialsAvailable) {
            root.syncedAccounts = [];
            root.offline = false;
            root.lastOutcome = "signin";
            root.statusMessage = "Sign in to Gmail";
            root.schedulePoll();
            return;
        }

        const refreshTokens = root.keyring?.refreshTokens ?? {};
        const accounts = root.configuredAccounts
            .filter(account => account.enabled !== false)
            .map(account => ({
                id: account.id,
                email: account.email,
                refreshToken: refreshTokens[account.id] ?? "",
                knownMessages: root.inboxCache[account.id]?.messages ?? [],
                historyId: root.inboxCache[account.id]?.historyId ?? ""
            }));
        root.lastOutcome = "syncing";
        root.statusMessage = "Checking Gmail";
        root.startProcess(syncProcess, {
            clientId: root.keyring.clientId,
            clientSecret: root.keyring.clientSecret,
            accounts: accounts
        });
    }

    // One-shot timer rearmed after every attempt, so the countdown shown in the
    // popover and the actual poll always agree, and so repeated failures stretch it.
    function schedulePoll() {
        if (!root.enabled || !root.hasEnabledAccounts) {
            pollTimer.stop();
            root.nextRetryAt = 0;
            return;
        }
        pollTimer.interval = root.retryDelayMs;
        root.nextRetryAt = Date.now() + pollTimer.interval;
        pollTimer.restart();
    }

    function startProcess(process, payload) {
        process.stdinEnabled = true;
        process.payload = JSON.stringify(payload);
        process.running = true;
    }

    function notificationsEnabledFor(account) {
        return root.notifyOnNewMail && account?.notify !== false;
    }

    // Fold one helper response into the cache. Accounts that failed keep their
    // last good entry, so one dead inbox never blanks the panel. Returns whether
    // any account came back clean.
    function absorbResults(results) {
        const configById = {};
        for (const account of root.configuredAccounts)
            configById[account.id] = account;

        const updated = Object.assign({}, root.inboxCache);
        const fresh = [];
        const now = Date.now();
        const canNotify = root.hasSuccessfulSyncThisRun;
        let succeeded = false;

        for (const result of results) {
            if (result.error)
                continue;
            succeeded = true;
            const messages = result.messages ?? [];
            const previous = updated[result.id];
            // Only mail whose id was absent from the previous sync counts as new, so
            // reading a message elsewhere — which only moves the count — stays quiet.
            // With no previous sync there is nothing to compare against: seed and stay silent.
            if (canNotify && previous?.seenIds && root.notificationsEnabledFor(configById[result.id])) {
                const seen = {};
                for (const id of previous.seenIds)
                    seen[id] = true;
                for (const message of messages) {
                    if (message.read || seen[message.id])
                        continue;
                    fresh.push(Object.assign({}, message, {
                        accountLabel: configById[result.id]?.label || result.email
                    }));
                }
            }
            updated[result.id] = {
                messages: messages,
                historyId: result.historyId ?? "",
                unread: result.unread ?? null,
                total: result.total ?? 0,
                seenIds: messages.map(message => message.id),
                syncedAt: now
            };
        }

        root.inboxCache = updated;
        if (succeeded) {
            root.lastSync = new Date(now);
            root.persistCache();
            root.hasSuccessfulSyncThisRun = true;
        }
        root.notifyNewMail(fresh);
        return succeeded;
    }

    function notifyNewMail(fresh) {
        if (fresh.length === 0)
            return;
        if (fresh.length > root.notificationBurstLimit) {
            const senders = fresh.slice(0, root.notificationBurstLimit).map(message => message.sender).join(", ");
            Quickshell.execDetached([
                "notify-send",
                `${fresh.length} new messages`,
                `${senders} and ${fresh.length - root.notificationBurstLimit} more`,
                "-a", "Gmail",
                "-h", "string:desktop-entry:illogical-impulse",
                "--hint=int:transient:1"
            ]);
            return;
        }
        for (const message of fresh) {
            Quickshell.execDetached([
                "notify-send",
                message.sender,
                `${message.subject}\n${message.accountLabel}`,
                "-a", "Gmail",
                "-h", "string:desktop-entry:illogical-impulse",
                "--hint=int:transient:1"
            ]);
        }
    }

    function finishSync(exitCode) {
        const response = root.parseOutput(syncOutput.text);
        const results = response?.accounts ?? [];
        if (results.length > 0)
            root.syncedAccounts = results;
        const succeeded = results.length > 0 && root.absorbResults(results);

        root.offline = exitCode === root.exitNetwork
            || results.some(result => result.error === "network");

        if (exitCode === 0) {
            root.lastOutcome = "success";
            root.statusMessage = "Unread counts updated";
        } else if (exitCode === root.exitExpired) {
            root.lastOutcome = "expired";
            root.statusMessage = succeeded
                ? "One Gmail account needs signing in again"
                : "Gmail authorisation expired. Sign in again.";
        } else if (exitCode === root.exitNetwork) {
            root.lastOutcome = "network";
            root.statusMessage = succeeded ? "Some Gmail accounts are unreachable" : "Gmail is unreachable";
        } else {
            root.lastOutcome = "error";
            root.statusMessage = "Gmail sync failed";
        }

        // Back off while nothing gets through; one clean account restores the pace.
        root.failureStreak = succeeded ? 0 : Math.min(root.failureStreak + 1, root.maxFailureStreak);
        root.schedulePoll();
        if (root.refreshAfterAction) {
            root.refreshAfterAction = false;
            root.sync();
        }
    }

    function finishLogin(exitCode) {
        const response = root.parseOutput(loginOutput.text);
        const account = response?.account;
        if (exitCode !== 0 || !account) {
            root.reconnectAccountId = "";
            root.lastOutcome = exitCode === root.exitExpired ? "expired" : "network";
            root.statusMessage = exitCode === root.exitExpired
                ? "Google sign-in was not completed"
                : "Could not complete Google sign-in";
            return;
        }

        root.pendingAccount = account;
        root.statusMessage = `Saving ${account.email}`;
        KeyringStorage.setNestedField(["gmail", "refreshTokens", account.id], account.refreshToken);
    }

    function recordPendingAccount() {
        const account = root.pendingAccount;
        if (!account)
            return;
        root.pendingAccount = null;
        const reconnectId = root.reconnectAccountId;
        root.reconnectAccountId = "";
        root.invalidateLabels(account.id);

        const accounts = Array.from(root.configuredAccounts);
        const existingIndex = accounts.findIndex(item => item.id === account.id);
        if (existingIndex >= 0) {
            accounts[existingIndex] = Object.assign({}, accounts[existingIndex], {
                email: account.email,
                enabled: true
            });
        } else {
            const usedColors = accounts.map(item => item.color);
            const color = root.accountColorKeys.find(key => !usedColors.includes(key))
                ?? root.accountColorKeys[accounts.length % root.accountColorKeys.length];
            accounts.push({
                id: account.id,
                label: account.email,
                email: account.email,
                color: color,
                enabled: true,
                notify: true
            });
        }
        Config.options.gmail.accounts = accounts;

        // Drop the stale expiry so the reconnected row recovers before the next poll.
        root.syncedAccounts = root.syncedAccounts.map(synced =>
            synced.id === account.id ? Object.assign({}, synced, { error: null }) : synced
        );
        root.lastOutcome = "success";
        root.statusMessage = reconnectId && reconnectId !== account.id
            ? `Signed in ${account.email} instead of the expired account`
            : `${account.email} signed in`;
        root.failureStreak = 0;
        root.sync();
    }

    function parseOutput(text) {
        try {
            return JSON.parse(text.trim());
        } catch (error) {
            console.warn(`[Gmail] Could not parse helper output: ${error.message}`);
            return null;
        }
    }

    function loadCache() {
        // A sync that already landed wins: the file is only ever the older copy.
        if (root.lastSync.getTime() > 0)
            return;
        let stored = null;
        try {
            stored = JSON.parse(cacheFile.text());
        } catch (error) {
            console.warn(`[Gmail] Could not parse the inbox cache: ${error.message}`);
            return;
        }
        if (!stored?.accounts)
            return;
        root.inboxCache = stored.accounts;
        root.lastSync = new Date(stored.lastSync ?? 0);
    }

    function persistCache() {
        cacheFile.setText(JSON.stringify({
            version: 1,
            lastSync: root.lastSync.getTime(),
            accounts: root.inboxCache
        }));
    }

    function removeAccount(accountId) {
        root.invalidateLabels(accountId);
        Config.options.gmail.accounts = root.configuredAccounts.filter(account => account.id !== accountId);
        KeyringStorage.removeNestedField(["gmail", "refreshTokens", accountId]);
        root.syncedAccounts = root.syncedAccounts.filter(account => account.id !== accountId);
        const updated = Object.assign({}, root.inboxCache);
        delete updated[accountId];
        root.inboxCache = updated;
        root.persistCache();
        root.statusMessage = "Gmail account removed";
    }

    function invalidateLabels(accountId) {
        const labels = Object.assign({}, root.labelsByAccount);
        delete labels[accountId];
        root.labelsByAccount = labels;
        const errors = Object.assign({}, root.labelErrorsByAccount);
        delete errors[accountId];
        root.labelErrorsByAccount = errors;
        root.pendingLabelAccounts = root.pendingLabelAccounts.filter(id => id !== accountId);
    }

    function setAccountLabel(accountId, label) {
        const trimmed = label.trim();
        if (!trimmed)
            return;
        Config.options.gmail.accounts = root.configuredAccounts.map(account =>
            account.id === accountId ? Object.assign({}, account, { label: trimmed }) : account
        );
    }

    function setAccountColor(accountId, colorKey) {
        if (!root.accountColorKeys.includes(colorKey))
            return;
        Config.options.gmail.accounts = root.configuredAccounts.map(account =>
            account.id === accountId ? Object.assign({}, account, { color: colorKey }) : account
        );
    }

    function setAccountEnabled(accountId, enabled) {
        Config.options.gmail.accounts = root.configuredAccounts.map(account =>
            account.id === accountId ? Object.assign({}, account, { enabled: enabled }) : account
        );
        if (enabled)
            root.sync();
    }

    function setAccountNotify(accountId, notify) {
        Config.options.gmail.accounts = root.configuredAccounts.map(account =>
            account.id === accountId ? Object.assign({}, account, { notify: notify }) : account
        );
    }

    onEnabledChanged: {
        if (root.enabled)
            root.sync();
        else
            root.schedulePoll();
    }

    onRefreshIntervalMinutesChanged: root.schedulePoll()

    onConfiguredAccountsChanged: {
        KeyringStorage.fetchKeyringData();
    }

    Component.onCompleted: {
        if (KeyringStorage.loaded)
            deferredSync.restart();
        else
            KeyringStorage.fetchKeyringData();
    }

    Connections {
        target: KeyringStorage

        function onLoadedChanged() {
            if (KeyringStorage.loaded)
                deferredSync.restart();
        }

        function onDataLoaded() {
            deferredSync.restart();
        }

        function onSaveFinished(success) {
            if (!root.pendingAccount)
                return;
            if (success) {
                root.recordPendingAccount();
                return;
            }
            root.pendingAccount = null;
            root.reconnectAccountId = "";
            root.lastOutcome = "error";
            root.statusMessage = "Could not save the Gmail refresh token";
        }
    }

    FileView {
        id: cacheFile
        path: Qt.resolvedUrl(Directories.gmailCachePath)

        onLoaded: root.loadCache()
        onLoadFailed: error => {
            if (error !== FileViewError.FileNotFound)
                console.warn(`[Gmail] Could not read the inbox cache: ${error}`);
        }
    }

    Timer {
        id: deferredSync
        interval: Appearance.animation.elementMoveFast.duration
        onTriggered: root.sync()
    }

    Timer {
        id: pollTimer
        interval: root.refreshIntervalMinutes * 60000
        running: false
        repeat: false
        onTriggered: root.sync()
    }

    Process {
        id: loginProcess
        property string payload: ""
        command: ["/usr/bin/python3", Quickshell.shellPath("scripts/gmail/gmail_helper.py"), "login"]

        stdout: StdioCollector { id: loginOutput }

        onRunningChanged: {
            if (!running)
                return;
            write(payload);
            payload = "";
            stdinEnabled = false;
        }
        onExited: exitCode => root.finishLogin(exitCode)
    }

    Process {
        id: syncProcess
        property string payload: ""
        command: ["/usr/bin/python3", Quickshell.shellPath("scripts/gmail/gmail_helper.py"), "sync"]

        stdout: StdioCollector { id: syncOutput }

        onRunningChanged: {
            if (!running)
                return;
            write(payload);
            payload = "";
            stdinEnabled = false;
        }
        onExited: exitCode => root.finishSync(exitCode)
    }

    Process {
        id: actionProcess
        property string payload: ""
        command: ["/usr/bin/python3", Quickshell.shellPath("scripts/gmail/gmail_helper.py"), "action"]

        stdout: StdioCollector { id: actionOutput }

        onRunningChanged: {
            if (!running)
                return;
            write(payload);
            payload = "";
            stdinEnabled = false;
        }
        onExited: exitCode => root.finishAction(exitCode)
    }

    Process {
        id: readProcess
        property string payload: ""
        command: ["/usr/bin/python3", Quickshell.shellPath("scripts/gmail/gmail_helper.py"), "read"]

        stdout: StdioCollector { id: readOutput }

        onRunningChanged: {
            if (!running)
                return;
            write(payload);
            payload = "";
            stdinEnabled = false;
        }
        onExited: exitCode => root.finishRead(exitCode)
    }

    Process {
        id: labelProcess
        property string payload: ""
        command: ["/usr/bin/python3", Quickshell.shellPath("scripts/gmail/gmail_helper.py"), "action"]

        stdout: StdioCollector { id: labelOutput }

        onRunningChanged: {
            if (!running)
                return;
            write(payload);
            payload = "";
            stdinEnabled = false;
        }
        onExited: exitCode => root.finishLabelFetch(exitCode)
    }

    IpcHandler {
        target: "gmail"

        function sync(): void {
            root.sync();
        }

        function retry(): void {
            root.retryNow();
        }

        function reconnect(accountId: string): void {
            root.reconnect(accountId);
        }

        function status(): string {
            return JSON.stringify({
                outcome: root.lastOutcome,
                syncing: root.syncing,
                offline: root.offline,
                failureStreak: root.failureStreak,
                retryDelayMs: root.retryDelayMs,
                secondsToRetry: root.nextRetryAt > 0
                    ? Math.max(0, Math.round((root.nextRetryAt - Date.now()) / 1000))
                    : 0,
                lastSync: root.lastSync.getTime(),
                configuredAccounts: root.configuredAccounts.length,
                accounts: root.accounts
            });
        }
    }
}
