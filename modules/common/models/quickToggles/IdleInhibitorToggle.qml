import QtQuick
import Quickshell
import qs
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.services

QuickToggleModel {
    name: "Keep awake"
    toggled: Idle.inhibit
    icon: "coffee"
    mainAction: () => {
        Idle.toggleInhibit();
    }
    tooltipText: "Keep system awake"
}
