pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common
import qs.modules.common.functions

Singleton {
    id: root

    readonly property var options: Config.options?.bar?.aiUsage
    readonly property bool enabled: options?.enable ?? true
    readonly property bool paused: options?.paused ?? false
    readonly property int refreshIntervalMinutes: Math.max(1, options?.refreshIntervalMinutes ?? 5)
    readonly property int staleAfterSeconds: refreshIntervalMinutes * 120
    readonly property string codexCachePath: FileUtils.trimFileProtocol(`${Directories.state}/user/codex-usage.json`)
    readonly property string claudeCachePath: FileUtils.trimFileProtocol(`${Directories.state}/user/claude-usage.json`)

    property var codex: null
    property var claude: null
    readonly property bool syncing: codexSyncProcess.running || claudeSyncProcess.running
    property string lastError: ""
    property double nowSeconds: Date.now() / 1000

    function loadProvider(fileView, providerName) {
        const contents = fileView.text().trim();
        if (contents.length === 0)
            return;
        try {
            const parsed = JSON.parse(contents);
            if (providerName === "codex")
                root.codex = parsed;
            else
                root.claude = parsed;
        } catch (error) {
            console.warn(`[AiUsage] Could not parse ${providerName} usage cache: ${error.message}`);
        }
    }

    function sync() {
        claudeCache.reload();
        root.lastError = "";
        if (!codexSyncProcess.running)
            codexSyncProcess.running = true;
        if (!claudeSyncProcess.running)
            claudeSyncProcess.running = true;
    }

    function togglePaused() {
        Config.options.bar.aiUsage.paused = !root.paused;
    }

    function isStale(provider) {
        if (!provider || !provider.capturedAt)
            return true;
        if (provider.fiveHour?.resetsAt && root.nowSeconds >= provider.fiveHour.resetsAt)
            return true;
        return root.nowSeconds - provider.capturedAt > root.staleAfterSeconds;
    }

    function remainingPercent(target, window = "fiveHour") {
        if (!target)
            return null;
        let used;
        if (typeof window === "object" && window !== null) {
            used = window.usedPercent;
        } else if (target.usedPercent !== undefined) {
            used = target.usedPercent;
        } else {
            used = target[window]?.usedPercent;
        }
        if (used === undefined || used === null)
            return null;
        return Math.max(0, Math.min(100, Math.round(100 - used)));
    }

    function usageLevel(provider, window = "fiveHour") {
        if (!provider || root.isStale(provider))
            return "unknown";
        const remaining = root.remainingPercent(provider, window);
        if (remaining === null)
            return "unknown";
        if (remaining <= 20)
            return "critical";
        if (remaining <= 40)
            return "warning";
        return "normal";
    }

    function level(provider, window = "fiveHour") {
        return root.usageLevel(provider, window);
    }

    function remainingText(provider) {
        const remaining = root.remainingPercent(provider);
        return remaining === null ? "--" : `${remaining}%`;
    }

    function resetText(window) {
        if (!window?.resetsAt)
            return "Unknown";
        return Qt.formatDateTime(new Date(window.resetsAt * 1000), "ddd HH:mm");
    }

    function ageText(provider) {
        if (!provider?.capturedAt)
            return "Never";
        const seconds = Math.max(0, Math.floor(root.nowSeconds - provider.capturedAt));
        if (seconds < 60)
            return "Just now";
        const minutes = Math.floor(seconds / 60);
        if (minutes < 60)
            return `${minutes} min ago`;
        const hours = Math.floor(minutes / 60);
        return `${hours} hr ago`;
    }

    onPausedChanged: {
        if (!root.paused && root.enabled)
            root.sync();
    }

    Component.onCompleted: {
        codexCache.reload();
        claudeCache.reload();
        if (root.enabled && !root.paused)
            initialSync.start();
    }

    Timer {
        id: initialSync
        interval: 500
        onTriggered: root.sync()
    }

    Timer {
        interval: root.refreshIntervalMinutes * 60000
        running: root.enabled && !root.paused
        repeat: true
        onTriggered: root.sync()
    }

    Timer {
        interval: 30000
        running: root.enabled
        repeat: true
        onTriggered: root.nowSeconds = Date.now() / 1000
    }

    FileView {
        id: codexCache
        path: root.codexCachePath
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.loadProvider(codexCache, "codex")
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound)
                setText("{}");
        }
    }

    FileView {
        id: claudeCache
        path: root.claudeCachePath
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.loadProvider(claudeCache, "claude")
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound)
                setText("{}");
        }
    }

    Process {
        id: codexSyncProcess
        command: [FileUtils.trimFileProtocol(`${Directories.scriptPath}/ai/codex-usage.sh`)]

        stderr: StdioCollector {
            id: codexErrorCollector
        }

        onExited: exitCode => {
            root.nowSeconds = Date.now() / 1000;
            codexCache.reload();
            if (exitCode !== 0) {
                root.lastError = codexErrorCollector.text.trim() || "Codex sync failed";
                console.warn(`[AiUsage] ${root.lastError}`);
            }
        }
    }

    Process {
        id: claudeSyncProcess
        command: [FileUtils.trimFileProtocol(`${Directories.scriptPath}/ai/claude-usage.sh`)]

        stderr: StdioCollector {
            id: claudeErrorCollector
        }

        onExited: exitCode => {
            root.nowSeconds = Date.now() / 1000;
            claudeCache.reload();
            if (exitCode !== 0) {
                root.lastError = claudeErrorCollector.text.trim() || "Claude sync failed";
                console.warn(`[AiUsage] ${root.lastError}`);
            }
        }
    }

    IpcHandler {
        target: "aiUsage"

        function sync(): void {
            root.sync();
        }

        function togglePause(): void {
            root.togglePaused();
        }

        function status(): string {
            return JSON.stringify({
                paused: root.paused,
                syncing: root.syncing,
                refreshIntervalMinutes: root.refreshIntervalMinutes,
                claudeRemainingPercent: root.remainingPercent(root.claude),
                claudeStale: root.isStale(root.claude),
                codexRemainingPercent: root.remainingPercent(root.codex),
                codexStale: root.isStale(root.codex),
                lastError: root.lastError
            });
        }
    }
}
