import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.services

StyledPopup {
    id: root

    // Hyprland emits no event for a mode change, so HyprlandData.monitors can be stale by the
    // time the popup opens (the `power` CLI switches refresh rate on plug/unplug). Re-read on
    // open; the popup only exists while hovered, so this costs one hyprctl call per hover.
    readonly property var focusedMonitor: HyprlandData.monitors.find(m => m.focused) ?? HyprlandData.monitors[0] ?? null

    onActiveChanged: if (root.active)
        HyprlandData.updateMonitors()

    ColumnLayout {
        id: columnLayout

        anchors.centerIn: parent
        spacing: 4

        // Header
        StyledPopupHeaderRow {
            icon: "battery_android_full"
            label: "Battery"
        }

        StyledPopupValueRow {
            function formatTime(seconds) {
                var h = Math.floor(seconds / 3600);
                var m = Math.floor((seconds % 3600) / 60);
                if (h > 0)
                    return `${h}h, ${m}m`;
                else
                    return `${m}m`;
            }

            visible: {
                let timeValue = Battery.isCharging ? Battery.timeToFull : Battery.timeToEmpty;
                let power = Battery.energyRate;
                return !(Battery.chargeState == 4 || timeValue <= 0 || power <= 0.01);
            }
            icon: "schedule"
            label: Battery.isCharging ? "Time to full:" : "Time to empty:"
            value: {
                if (Battery.isCharging)
                    return formatTime(Battery.timeToFull);
                else
                    return formatTime(Battery.timeToEmpty);
            }
        }

        StyledPopupValueRow {
            visible: !(Battery.chargeState != 4 && Battery.energyRate == 0)
            icon: "bolt"
            label: {
                if (Battery.chargeState == 4)
                    return "Fully charged";
                else if (Battery.chargeState == 1)
                    return "Charging:";
                else
                    return "Discharging:";
            }
            value: {
                if (Battery.chargeState == 4)
                    return "";
                else
                    return `${Battery.energyRate.toFixed(2)}W`;
            }
        }

        StyledPopupValueRow {
            icon: "heart_check"
            label: "Health:"
            value: `${(Battery.health).toFixed(1)}%`
        }

        StyledPopupValueRow {
            visible: (root.focusedMonitor?.refreshRate ?? 0) > 0
            icon: "monitor"
            label: "Refresh:"
            value: {
                const monitor = root.focusedMonitor;
                if (!monitor)
                    return "";
                // VRR is worth surfacing: mode-setting drops it silently if not preserved.
                return `${Math.round(monitor.refreshRate)}Hz${monitor.vrr ? " · VRR" : ""}`;
            }
        }

    }

}
