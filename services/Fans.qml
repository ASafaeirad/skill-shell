pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

/**
* Fan sensors and fan-curve editing, backed by the `fan` CLI (~/.local/bin/fan), which is the
* single source of truth for what a fan action means. This service decides *when* to read or
* write, never *what* a curve or the full-speed override does -- that lives in the script, so
* the terminal and this page cannot drift apart.
*
* Curves are carried as raw PWM (0-255) end to end. asusctl truncates when it renders a
* percentage, so a curve that round-trips through percent loses ~1% per cycle and ratchets
* itself down; percent exists here only for display.
*/
Singleton {
    id: root

    readonly property int sensorInterval: 2000

    // The settings page raises this while it is on screen. Nothing polls otherwise: this
    // service exists for one page, and a shell-wide 2s subprocess is a battery cost every
    // session would pay to watch sensors nobody is looking at.
    property bool monitoring: false

    // -1 means "no reading". A missing sensor and a genuine zero must not look the same:
    // the dGPU has no temperature at all while it is runtime-suspended, and 0 degrees would
    // be a lie rather than an absence.
    property int cpuTemp: -1
    property int gpuTemp: -1
    property string dgpuStatus: ""
    property string platformProfile: ""
    property var fanSpeeds: []

    // Curve state, as last read back from the hardware.
    property string profile: ""
    // Whether the flat-out override is engaged. No longer settable on its own -- the Max
    // profile is the only way in, and Quiet or Default are the way out -- but still read,
    // because it is half of what makes Max the active mode and it locks curve editing.
    property bool fullSpeed: false
    property bool curveEnabled: false
    property var curve: []
    property var fanData: ({})
    // The three fans ship with meaningfully different factory curves. The editor writes one
    // curve to all three, so the page needs to be able to say so before it flattens them.
    property bool fansDiffer: false

    property bool ready: false
    property bool busy: false
    property string lastError: ""

    readonly property var profileNames: ({
                                             "quiet": "Quiet",
                                             "balanced": "Balanced",
                                             "performance": "Performance"
                                         })

    readonly property var fanLabels: ({
                                          "cpu": "CPU",
                                          "gpu": "GPU",
                                          "mid": "Mid"
                                      })

    function pwmToPercent(pwm) {
        return Math.round(pwm / 255 * 100);
    }

    function percentToPwm(percent) {
        return Math.round(percent / 100 * 255);
    }

    function serialize(points) {
        return points.map(p => `${p.temp}c:${p.pwm}`).join(",");
    }

    // The three profile buttons. "max" is Performance *plus* the full-speed override, which
    // is what `fan max` does, so it is only that mode when both hold; Performance on its own
    // lights nothing rather than claiming a mode the machine is not actually in.
    readonly property string mode: {
        if (!root.ready)
            return "";
        if (root.fullSpeed)
            return root.profile === "Performance" ? "max" : "";
        if (root.profile === "Quiet")
            return "quiet";
        if (root.profile === "Balanced")
            return "default";
        return "";
    }

    readonly property var modeCommands: ({
                                             "quiet": "slow",
                                             "default": "default",
                                             "max": "max"
                                         })

    function refresh() {
        curveProc.exec(["fan", "curve", "get"]);
    }

    function setMode(mode) {
        const command = root.modeCommands[mode];
        if (root.busy || !command)
            return;
        root.busy = true;
        root.lastError = "";
        writeProc.exec(["fan", command]);
    }

    function applyCurve(points) {
        if (root.busy)
            return;
        root.busy = true;
        root.lastError = "";
        writeProc.exec(["fan", "curve", "set", root.serialize(points)]);
    }

    function resetCurve() {
        if (root.busy)
            return;
        root.busy = true;
        root.lastError = "";
        writeProc.exec(["fan", "curve", "reset"]);
    }

    onMonitoringChanged: {
        if (!root.monitoring)
            return;
        sensorProc.exec(["fan", "sensors"]);
        root.refresh();
    }

    Timer {
        running: root.monitoring
        interval: root.sensorInterval
        repeat: true
        // Skipping a tick while the previous read is still in flight keeps a slow nvidia-smi
        // (it is allowed to take up to 2s) from stacking up one subprocess per tick.
        onTriggered: if (!sensorProc.running)
                         sensorProc.exec(["fan", "sensors"])
    }

    Process {
        id: sensorProc

        command: ["fan", "sensors"]

        stdout: StdioCollector {
            onStreamFinished: {
                let data;
                try {
                    data = JSON.parse(this.text);
                } catch (e) {
                    // A malformed sample is not worth surfacing: the next tick is 2s away and
                    // blanking the readout would make the page flicker on a single bad read.
                    console.warn("[Fans] could not parse sensors:", this.text);
                    return;
                }
                root.cpuTemp = data.cpuTemp ?? -1;
                root.gpuTemp = data.gpuTemp ?? -1;
                root.dgpuStatus = data.dgpu ?? "";
                root.platformProfile = data.profile ?? "";
                root.fanSpeeds = (data.fans ?? []).map(f => ({
                    "id": f.id,
                    "label": root.fanLabels[f.id] ?? f.id,
                    "rpm": f.rpm ?? -1
                }));

                // Something else can change the profile underneath us -- `power` does exactly
                // that on plug and unplug. This poll is the only thing watching, so let it
                // notice: the curve is per-profile, and would otherwise sit there being shown
                // and edited against a profile the machine already left.
                const active = root.profileNames[root.platformProfile] ?? "";
                if (root.ready && active.length > 0 && active !== root.profile && !root.busy &&
                        !curveProc.running)
                    root.refresh();
            }
        }
    }

    Process {
        id: curveProc

        command: ["fan", "curve", "get"]

        stdout: StdioCollector {
            onStreamFinished: {
                let data;
                try {
                    data = JSON.parse(this.text);
                } catch (e) {
                    root.lastError = "Could not read the current fan curve.";
                    return;
                }
                root.profile = data.profile ?? "";
                root.fullSpeed = data.fullSpeed ?? false;

                const fans = data.fans ?? [];
                let byId = {};
                for (const fan of fans)
                    byId[fan.id] = fan;
                root.fanData = byId;

                // The CPU fan seeds the editor: it is the one the CPU temperature shown above
                // the curve actually drives, so the numbers on screen agree with each other.
                const seed = byId["cpu"] ?? fans[0];
                root.curve = seed ? seed.points : [];
                root.curveEnabled = seed ? seed.enabled : false;
                root.fansDiffer = fans.length > 1 && fans.some(f => f.data !== fans[0].data);
                root.ready = true;
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (this.text.trim().length > 0)
                    console.warn("[Fans] curve get:", this.text.trim());
            }
        }
    }

    Process {
        id: writeProc

        command: ["fan", "curve", "get"]

        stderr: StdioCollector {
            id: writeErr

            onStreamFinished: {
                // `fan` prefixes its own diagnostics; strip that so the page shows a sentence
                // rather than a shell transcript.
                const message = this.text.trim().replace(/^fan:\s*/, "");
                if (message.length > 0)
                    root.lastError = message;
            }
        }

        onExited: exitCode => {
            root.busy = false;
            if (exitCode !== 0 && root.lastError.length === 0)
                root.lastError = `The fan command failed (exit ${exitCode}).`;
            // Always read back, including after a failure: a curve write touches three fans in
            // sequence and can land on some of them before failing, so the only trustworthy
            // state is what the hardware reports now.
            root.refresh();
        }
    }
}
