pragma Singleton

import qs.modules.common
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import QtQuick

/**
 * Applies AC/battery power policy by invoking the `power` CLI (~/.local/bin/power), which is
 * the single source of truth for what each state means. This service only decides *when* to
 * invoke it, never *what* the policy is -- profile names and refresh rates live in the script.
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

    // Last state actually applied, so a redundant UPower signal doesn't re-invoke the CLI.
    property int appliedState: -1  // -1 unknown, 0 on AC, 1 on battery

    function apply(reason) {
        if (!root.enabled)
            return;
        const want = root.onBattery ? 1 : 0;
        if (want === root.appliedState)
            return;
        root.appliedState = want;
        console.log(`[PowerProfile] ${reason}: applying ${want === 1 ? "battery" : "AC"} policy`);
        applyProc.running = false;
        applyProc.running = true;
    }

    onOnBatteryChanged: settleTimer.restart()

    onEnabledChanged: {
        if (!root.enabled)
            return;
        root.appliedState = -1;  // re-reconcile after being switched back on
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

        command: ["power", "auto"]

        // `power` is idempotent and exits non-zero only on real failure. Surfacing that
        // matters here: an earlier iteration of this project silently did nothing for hours.
        stderr: StdioCollector {
            onStreamFinished: {
                if (this.text.trim().length > 0)
                    console.warn(`[PowerProfile] power auto: ${this.text.trim()}`);
            }
        }

        onExited: exitCode => {
            if (exitCode !== 0) {
                console.warn(`[PowerProfile] power auto failed (exit ${exitCode}); will retry on next change`);
                root.appliedState = -1;
            }
        }
    }

    Component.onCompleted: {
        // Reconcile at startup: the shell may be starting after a state change it never saw
        // (fresh login, or a crash while plugged in).
        Qt.callLater(() => root.apply("shell startup"));
    }
}
