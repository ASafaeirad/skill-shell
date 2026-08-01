import QtQuick
import Quickshell
import qs
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.services

QuickToggleModel {
    name: "Virtual Keyboard"
    toggled: GlobalStates.oskOpen
    icon: toggled ? "keyboard_hide" : "keyboard"
    mainAction: () => {
        GlobalStates.oskOpen = !GlobalStates.oskOpen;
    }
    tooltipText: "On-screen keyboard"
}
