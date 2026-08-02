pragma Singleton

import qs.modules.common
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import QtQuick

/**
 * Applies power policy by invoking the `power` CLI (~/.local/bin/power), which is the single
 * source of truth for what each state means. This service only decides *when* to invoke it and
 * which mode is selected, never *what* a mode does -- profile names and refresh rates live in
 * the script. Modes: auto (follow the source), performance and powersaver (pinned on both).
 *
 * Trigger is UPower.onBattery (the AC line), deliberately not Battery.isPluggedIn. The latter
 * is `isCharging || PendingCharge`, which reads false once the battery reaches full while
 * still plugged in -- so unplugging at 100% would produce no change at all and the machine
 * would stay on AC policy on battery.
 */
Singleton {
    id: root

    // Referenced from shell.qml to force instantiation; singletons are otherwise lazy.
    function load() {
    }

    readonly property bool enabled: Config.options.battery.autoPowerProfile
    readonly property bool onBattery: UPower.onBattery
    readonly property string powerMode: Config.options.battery.powerMode

    // Last thing actually applied, so a redundant UPower signal doesn't re-invoke the CLI.
    // Keyed on mode as well as source: the same source under a new mode is a real change.
    property string appliedState: ""

    function apply(reason) {
        if (!root.enabled)
            return;
        const want = `${root.powerMode}:${root.onBattery ? "battery" : "ac"}`;
        if (want === root.appliedState)
            return;
        root.appliedState = want;
        console.log(`[PowerProfile] ${reason}: applying ${want}`);
        applyProc.running = false;
        // Set the command imperatively rather than binding it to root.powerMode: a binding is
        // not guaranteed to have re-evaluated by the time this handler runs, so the process
        // could launch with the previous mode. That failed silently -- the CLI succeeds, it
        // just applies the wrong thing.
        applyProc.command = ["power", "mode", root.powerMode];
        applyProc.running = true;
    }

    onOnBatteryChanged: settleTimer.restart()

    // A mode change is user-initiated, so apply it at once rather than waiting out the settle
    // timer, which exists only to absorb AC-line bounce.
    onPowerModeChanged: root.apply("mode changed")

    onEnabledChanged: {
        if (!root.enabled)
            return;
        root.appliedState = "";  // re-reconcile after being switched back on
        settleTimer.restart();
    }

    // Plugging in bounces the AC line; let it settle rather than invoking the CLI per edge.
    Timer {
        id: settleTimer

        interval: 1000
        onTriggered: root.apply("power source changed")
    }

    Process {
        id: applyProc

        // Replaced on every apply(); see the comment there.
        command: ["power", "mode", "auto"]

        // `power` is idempotent and exits non-zero only on real failure. Surfacing that
        // matters here: an earlier iteration of this project silently did nothing for hours.
        stderr: StdioCollector {
            onStreamFinished: {
                if (this.text.trim().length > 0)
                    console.warn(`[PowerProfile] power mode: ${this.text.trim()}`);
            }
        }

        onExited: exitCode => {
            if (exitCode === 0)
                return;
            // apply() kills any run still in flight before starting the next one, so the old
            // process reports SIGTERM. That is this service superseding itself, not a failure:
            // warning about it would train the reader to ignore a warning that does matter.
            if (exitCode === 15 && applyProc.running)
                return;
            console.warn(`[PowerProfile] power mode failed (exit ${exitCode}); will retry on next change`);
            root.appliedState = "";
        }
    }

    Component.onCompleted: {
        // Reconcile at startup: the shell may be starting after a state change it never saw
        // (fresh login, or a crash while plugged in).
        Qt.callLater(() => root.apply("shell startup"));
    }
}
