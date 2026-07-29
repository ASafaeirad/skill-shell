import QtQuick
import Quickshell
import qs
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.services

QuickToggleModel {
    name: Translation.tr("Screen snip")
    hasStatusText: false
    toggled: false
    icon: "screenshot_region"
    mainAction: () => {
        GlobalStates.sidebarRightOpen = false;
        delayedActionTimer.start();
    }
    tooltipText: Translation.tr("Screen snip")

    Timer {
        id: delayedActionTimer

        interval: 300
        repeat: false
        onTriggered: {
            Quickshell.execDetached(["qs", "-p", Quickshell.shellPath(""), "ipc", "call", "region", "screenshot"]);
        }
    }

}
