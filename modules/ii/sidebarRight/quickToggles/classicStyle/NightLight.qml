import QtQuick
import Quickshell.Io
import qs.modules.common
import qs.modules.common.widgets
import qs.services

QuickToggleButton {
    id: nightLightButton

    toggled: Config.options.light.night.automatic || Hyprsunset.temperatureActive
    buttonIcon: Config.options.light.night.automatic ? "night_sight_auto" : "bedtime"
    onClicked: {
        Hyprsunset.toggleTemperature();
    }
    altAction: () => {
        Config.options.light.night.automatic = !Config.options.light.night.automatic;
    }
    Component.onCompleted: {
        Hyprsunset.fetchState();
    }

    StyledToolTip {
        text: `${Translation.tr("Night Light")} · ${
            Config.options.light.night.automatic ? Translation.tr("Automatic") : Translation.tr("Manual")
        } · ${
            Hyprsunset.temperatureActive ? Translation.tr("Enabled now") : Translation.tr("Disabled now")
        }`
    }

}
