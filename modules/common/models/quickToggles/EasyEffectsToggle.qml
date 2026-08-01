import QtQuick
import Quickshell
import qs
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.services

QuickToggleModel {
    name: "EasyEffects"
    available: EasyEffects.available
    toggled: EasyEffects.active
    icon: "graphic_eq"
    Component.onCompleted: {
        EasyEffects.fetchActiveState();
    }
    mainAction: () => {
        EasyEffects.toggle();
    }
    altAction: () => {
        Quickshell.execDetached(["bash", "-c", "flatpak run com.github.wwmm.easyeffects || easyeffects"]);
        GlobalStates.sidebarRightOpen = false;
    }
    tooltipText: "EasyEffects | Right-click to configure"
}
