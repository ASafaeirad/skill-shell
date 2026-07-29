import QtQuick
import Quickshell
import qs
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.services

QuickToggleModel {
    property bool auto: Config.options.light.night.automatic
    property bool activeNow: Hyprsunset.temperatureActive

    name: auto
        ? `${Translation.tr("Night Light")} · ${Translation.tr("Automatic")}`
        : Translation.tr("Night Light")
    statusText: activeNow
        ? Translation.tr("Enabled now")
        : (auto ? Translation.tr("Disabled now") : Translation.tr("Disabled"))
    // Keep the control visibly enabled when automatic mode is configured,
    // while statusText reports whether the temperature filter is active now.
    toggled: auto || activeNow
    icon: auto ? "night_sight_auto" : "bedtime"
    mainAction: () => {
        Hyprsunset.toggleTemperature();
    }
    hasMenu: true
    Component.onCompleted: {
        Hyprsunset.fetchState();
    }
    tooltipText: Translation.tr("Night Light | Right-click to configure")
}
