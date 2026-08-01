pragma Singleton

import QtQuick
import Quickshell

Singleton {
    readonly property string bluetooth: "kcmshell6 kcm_bluetooth"
    readonly property string changePassword: "kitty -1 --hold=yes fish -i -c 'passwd'"
    readonly property string network: "kcmshell6 kcm_networkmanagement"
    readonly property string manageUser: "kcmshell6 kcm_users"
    readonly property string networkEthernet: "kcmshell6 kcm_networkmanagement"
    readonly property string taskManager: "plasma-systemmonitor --page-name Processes"
    readonly property string terminal: "kitty -1" // This is only for shell actions
    readonly property string volumeMixer: `~/.config/hypr/hyprland/scripts/launch_first_available.sh "pavucontrol-qt" "pavucontrol"`
}
