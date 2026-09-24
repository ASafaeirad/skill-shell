import QtQuick
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

QuickToggleModel {
    name: "Audio input"
    statusText: toggled ? "Enabled" : "Muted"
    toggled: !Audio.source?.audio?.muted
    icon: Audio.source?.audio?.muted ? "mic_off" : "mic"
    mainAction: () => {
        Audio.toggleMicMute()
    }
    hasMenu: true
    altAction: () => {
        Quickshell.execDetached(["bash", "-c", `${Apps.volumeMixer}`]);
        GlobalStates.sidebarRight?.close();
    }

    tooltipText: "Audio input | Right-click for volume mixer & device selector"
}
