import QtQuick
import Quickshell.Io
import qs.modules.common.models.hyprland
import qs.services

QuickToggleModel {
    id: root

    name: "Game mode"
    toggled: !confOpt.value
    icon: "gamepad"
    mainAction: () => {
        if (devicesProc.running)
            return;
        devicesProc.running = true;
    }

    function applyGameMode(touchpadKeys) {
        root.toggled = !root.toggled;
        if (root.toggled) {
            const entries = {
                "animations:enabled": 0,
                "decoration:shadow:enabled": 0,
                "decoration:blur:enabled": 0,
                "general:gaps_in": 0,
                "general:gaps_out": 0,
                "general:border_size": 1,
                "decoration:rounding": 0,
                "general:allow_tearing": 1
            };
            for (const key of touchpadKeys)
                entries[key] = "false";
            HyprlandConfig.setMany(entries);
        } else {
            HyprlandConfig.resetMany(["animations:enabled", "decoration:shadow:enabled", "decoration:blur:enabled", "general:gaps_in", "general:gaps_out", "general:border_size", "decoration:rounding", "general:allow_tearing"].concat(touchpadKeys));
        }
    }
    tooltipText: "Game mode"

    HyprlandConfigOption {
        id: confOpt

        key: "animations:enabled"
    }

    Process {
        id: devicesProc
        command: ["hyprctl", "devices", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    // Hyprland lists touchpads under mice without a device type.
                    const mice = JSON.parse(text).mice ?? [];
                    const keys = mice.filter(device => /touchpad/i.test(device.name))
                        .map(device => `device:${device.name}:enabled`);
                    root.applyGameMode(keys);
                } catch (error) {
                    console.warn("[GameModeToggle] Failed to read input devices:", error);
                }
            }
        }
    }

}
