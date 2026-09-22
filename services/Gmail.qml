pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common
import qs.modules.common.functions

Singleton {
    id: root

    readonly property var options: Config.options?.gmail
    readonly property bool enabled: options?.enable ?? false
    readonly property int refreshIntervalMinutes: Math.max(1, options?.refreshIntervalMinutes ?? 5)
    readonly property var configuredAccounts: options?.accounts ?? []
    readonly property var keyring: KeyringStorage.keyringData?.gmail ?? null
    readonly property bool credentialsAvailable: KeyringStorage.loaded
        && (keyring?.clientId?.length ?? 0) > 0
        && (keyring?.clientSecret?.length ?? 0) > 0
    readonly property bool hasEnabledAccounts: configuredAccounts.some(account => account.enabled !== false)
    readonly property bool visible: enabled && hasEnabledAccounts
    readonly property bool syncing: syncProcess.running
    readonly property bool signingIn: loginProcess.running
    readonly property string savedClientId: keyring?.clientId ?? ""
    readonly property bool hasSavedClientSecret: (keyring?.clientSecret?.length ?? 0) > 0

    property var syncedAccounts: []
    property string lastOutcome: credentialsAvailable ? "idle" : "signin"
    property string statusMessage: credentialsAvailable ? "" : "Sign in to Gmail"

    readonly property var accounts: {
        const syncedById = {};
        for (const synced of root.syncedAccounts)
            syncedById[synced.id] = synced;
        return root.configuredAccounts
            .filter(account => account.enabled !== false)
            .map(account => {
                const synced = syncedById[account.id];
                return Object.assign({}, account, {
                    unread: synced?.unread ?? null,
                    error: synced?.error ?? null
                });
            });
    }

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
        root.lastOutcome = "signin";
        root.statusMessage = "Complete sign-in in your browser";
        root.startProcess(loginProcess, {
            clientId: root.keyring.clientId,
            clientSecret: root.keyring.clientSecret
        });
    }

    function sync() {
        if (root.syncing || !root.enabled || !root.hasEnabledAccounts)
            return;
        if (!root.credentialsAvailable) {
            root.syncedAccounts = [];
            root.lastOutcome = "signin";
            root.statusMessage = "Sign in to Gmail";
            return;
        }

        const refreshTokens = root.keyring?.refreshTokens ?? {};
        const accounts = root.configuredAccounts
            .filter(account => account.enabled !== false)
            .map(account => ({
                id: account.id,
                email: account.email,
                refreshToken: refreshTokens[account.id] ?? ""
            }));
        root.lastOutcome = "syncing";
        root.statusMessage = "Checking Gmail";
        root.startProcess(syncProcess, {
            clientId: root.keyring.clientId,
            clientSecret: root.keyring.clientSecret,
            accounts: accounts
        });
    }

    function startProcess(process, payload) {
        process.stdinEnabled = true;
        process.payload = JSON.stringify(payload);
        process.running = true;
    }

    function finishSync(exitCode) {
        const response = root.parseOutput(syncOutput.text);
        if (response?.accounts)
            root.syncedAccounts = response.accounts;
        if (exitCode === 0) {
            root.lastOutcome = "success";
            root.statusMessage = "Unread counts updated";
        } else if (exitCode === 2) {
            root.lastOutcome = "expired";
            root.statusMessage = "Gmail authorisation expired. Sign in again.";
        } else if (exitCode === 3) {
            root.lastOutcome = "network";
            root.statusMessage = "Gmail is unreachable";
        } else {
            root.lastOutcome = "error";
            root.statusMessage = "Gmail sync failed";
        }
    }

    function finishLogin(exitCode) {
        const response = root.parseOutput(loginOutput.text);
        const account = response?.account;
        if (exitCode !== 0 || !account) {
            root.lastOutcome = exitCode === 2 ? "expired" : "network";
            root.statusMessage = exitCode === 2
                ? "Google sign-in was not completed"
                : "Could not complete Google sign-in";
            return;
        }

        KeyringStorage.setNestedField(["gmail", "refreshTokens", account.id], account.refreshToken);
        const accounts = Array.from(root.configuredAccounts);
        const existingIndex = accounts.findIndex(item => item.id === account.id);
        if (existingIndex >= 0) {
            accounts[existingIndex] = Object.assign({}, accounts[existingIndex], {
                email: account.email,
                enabled: true
            });
        } else {
            const palette = ["term1", "term2", "term3", "term4", "term5", "term6"];
            accounts.push({
                id: account.id,
                label: account.email,
                email: account.email,
                color: palette[accounts.length % palette.length],
                enabled: true
            });
        }
        Config.options.gmail.accounts = accounts;
        root.lastOutcome = "success";
        root.statusMessage = `${account.email} signed in`;
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

    function removeAccount(accountId) {
        Config.options.gmail.accounts = root.configuredAccounts.filter(account => account.id !== accountId);
        KeyringStorage.removeNestedField(["gmail", "refreshTokens", accountId]);
        root.syncedAccounts = root.syncedAccounts.filter(account => account.id !== accountId);
        root.statusMessage = "Gmail account removed";
    }

    function setAccountEnabled(accountId, enabled) {
        Config.options.gmail.accounts = root.configuredAccounts.map(account =>
            account.id === accountId ? Object.assign({}, account, { enabled: enabled }) : account
        );
        if (enabled)
            root.sync();
    }

    onEnabledChanged: {
        if (root.enabled)
            root.sync();
    }

    onConfiguredAccountsChanged: {
        if (root.enabled)
            deferredSync.restart();
    }

    Component.onCompleted: deferredSync.restart()

    Connections {
        target: KeyringStorage

        function onLoadedChanged() {
            if (KeyringStorage.loaded)
                deferredSync.restart();
        }
    }

    Timer {
        id: deferredSync
        interval: Appearance.animation.elementMoveFast.duration
        onTriggered: root.sync()
    }

    Timer {
        interval: root.refreshIntervalMinutes * 60000
        running: root.enabled && root.hasEnabledAccounts
        repeat: true
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

    IpcHandler {
        target: "gmail"

        function sync(): void {
            root.sync();
        }

        function status(): string {
            return JSON.stringify({
                outcome: root.lastOutcome,
                syncing: root.syncing,
                configuredAccounts: root.configuredAccounts.length,
                accounts: root.accounts
            });
        }
    }
}
