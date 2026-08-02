import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.widgets.sidebarRight.quickToggles
import qs.services

QuickToggleButton {
    toggled: Network.wifiStatus !== "disabled"
    buttonIcon: Network.materialSymbol
    onClicked: Network.toggleWifi()
    altAction: () => {
        Quickshell.execDetached(["bash", "-c", `${Network.ethernet ? Apps.networkEthernet : Apps.network}`]);
        GlobalStates.sidebarRightOpen = false;
    }

    StyledToolTip {
        text: "%1 | Right-click to configure".arg(Network.networkName)
    }

}
