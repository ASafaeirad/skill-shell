import QtQuick
import Quickshell
import qs
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.services

QuickToggleModel {
    name: "Color picker"
    hasStatusText: false
    toggled: false
    icon: "colorize"
    mainAction: () => {
        GlobalStates.sidebarRightOpen = false;
        delayedActionTimer.start();
    }
    tooltipText: "Color picker"

    Timer {
        id: delayedActionTimer

        interval: 300
        repeat: false
        onTriggered: {
            Quickshell.execDetached(["hyprpicker", "-a"]);
        }
    }

}
