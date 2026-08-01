import QtQuick
import Quickshell
import qs
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.services

QuickToggleModel {
    property bool sourceIsMonitor: SongRec.monitorSource === SongRec.MonitorSource.Monitor

    toggled: SongRec.running
    name: "Identify Music"
    statusText: toggled ? "Listening..." : sourceIsMonitor ? "System sound" : "Microphone"
    icon: toggled ? "music_cast" : (sourceIsMonitor ? "music_note" : "frame_person_mic")
    tooltipText: "Recognize music | Right-click to toggle source"
    mainAction: () => {
        SongRec.toggleRunning();
    }
    altAction: () => {
        SongRec.toggleMonitorSource();
    }
}
