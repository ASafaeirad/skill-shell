import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs
import qs.modules.common.widgets
import qs.services

QuickToggleButton {
    id: root

    visible: EasyEffects.available
    toggled: EasyEffects.active
    buttonIcon: "instant_mix"
    Component.onCompleted: {
        EasyEffects.fetchActiveState();
    }
    onClicked: {
        EasyEffects.toggle();
    }
    altAction: () => {
        Quickshell.execDetached(["bash", "-c", "flatpak run com.github.wwmm.easyeffects || easyeffects"]);
        GlobalStates.sidebarRightOpen = false;
    }

    StyledToolTip {
        text: "EasyEffects | Right-click to configure"
    }

}
