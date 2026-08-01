import QtQuick
import Quickshell
import qs
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.services

QuickToggleModel {
    name: "Dark Mode"
    statusText: Appearance.m3colors.darkmode ? "Dark" : "Light"
    toggled: Appearance.m3colors.darkmode
    icon: "contrast"
    mainAction: () => {
        if (Appearance.m3colors.darkmode)
            Quickshell.execDetached([Directories.wallpaperSwitchScriptPath, "--mode", "light", "--noswitch"]);
        else
            Quickshell.execDetached([Directories.wallpaperSwitchScriptPath, "--mode", "dark", "--noswitch"]);
    }
    tooltipText: "Dark Mode"
}
