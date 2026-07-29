import QtQuick
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.services

QuickToggleModel {
    name: Translation.tr("Internet")
    statusText: Network.networkName
    tooltipText: Translation.tr("%1 | Right-click to configure").arg(Network.networkName)
    icon: Network.materialSymbol
    toggled: Network.wifiStatus !== "disabled"
    mainAction: () => {
        return Network.toggleWifi();
    }
    hasMenu: true
}
