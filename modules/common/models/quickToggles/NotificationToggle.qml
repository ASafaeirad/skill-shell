import QtQuick
import Quickshell
import qs
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.services

QuickToggleModel {
    name: "Notifications"
    statusText: toggled ? "Show" : "Silent"
    toggled: !Notifications.silent
    icon: toggled ? "notifications_active" : "notifications_paused"
    mainAction: () => {
        Notifications.silent = !Notifications.silent;
    }
    tooltipText: "Show notifications"
}
