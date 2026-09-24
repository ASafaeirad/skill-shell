import QtQuick
import Quickshell
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.services

QuickToggleModel {
    name: "Internet"
    statusText: Network.networkName
    tooltipText: "%1 | Right-click to configure".arg(Network.networkName)
    icon: Network.materialSymbol
    toggled: Network.wifiStatus !== "disabled"
    mainAction: () => {
        return Network.toggleWifi();
    }
    hasMenu: true
    altAction: () => {
        Quickshell.execDetached(["bash", "-c", `${Network.ethernet ? Apps.networkEthernet : Apps.network}`]);
        GlobalStates.sidebarRight?.close();
    }
}

