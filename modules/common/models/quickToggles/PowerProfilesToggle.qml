import QtQuick
import Quickshell
import Quickshell.Services.UPower
import qs
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.services

/**
 * Cycles the user-selected power mode, not the raw profile. Writing Config here is the whole
 * action: services/PowerProfile.qml watches the option and invokes `power mode <name>`, which
 * owns what each mode actually does. Cycling profiles directly would be undone by the next
 * plug/unplug, since policy would have no record of the choice having been made.
 */
QuickToggleModel {
    id: root

    readonly property string mode: Config.options.battery.powerMode
    // What the machine is doing right now, which is only the same as the mode under `auto`.
    readonly property string activeProfile: {
        switch (PowerProfiles.profile) {
        case PowerProfile.PowerSaver:
            return "power-saver";
        case PowerProfile.Balanced:
            return "balanced";
        case PowerProfile.Performance:
            return "performance";
        }
        return "unknown";
    }

    name: "Power Profile"
    toggled: root.mode !== "auto"
    icon: {
        switch (root.mode) {
        case "performance":
            return "local_fire_department";
        case "powersaver":
            return "energy_savings_leaf";
        }
        return "autorenew";
    }
    statusText: {
        switch (root.mode) {
        case "performance":
            return "Performance";
        case "powersaver":
            return "Power Saver";
        }
        return "Auto";
    }
    mainAction: () => {
        switch (root.mode) {
        case "auto":
            Config.options.battery.powerMode = "performance";
            break;
        case "performance":
            Config.options.battery.powerMode = "powersaver";
            break;
        default:
            Config.options.battery.powerMode = "auto";
            break;
        }
    }
    tooltipText: {
        switch (root.mode) {
        case "performance":
            return `Performance and 240Hz on both AC and battery (now: ${root.activeProfile}).\nClick for Power Saver.`;
        case "powersaver":
            return `Power saver on both AC and battery (now: ${root.activeProfile}).\nRefresh rate still follows the power source.\nClick for Auto.`;
        }
        return `Following the power source (now: ${root.activeProfile}).\nClick for Performance.`;
    }
}
