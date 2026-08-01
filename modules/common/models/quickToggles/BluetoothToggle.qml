import QtQuick
import Quickshell.Bluetooth
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

QuickToggleModel {
    name: "Bluetooth"
    statusText: BluetoothStatus.firstActiveDevice?.name ?? "Not connected"
    tooltipText: "%1 | Right-click to configure".arg(
        (BluetoothStatus.firstActiveDevice?.name ?? "Bluetooth")
        + (BluetoothStatus.activeDeviceCount > 1 ? ` +${BluetoothStatus.activeDeviceCount - 1}` : "")
    )
    icon: BluetoothStatus.connected ? "bluetooth_connected" : BluetoothStatus.enabled ? "bluetooth" : "bluetooth_disabled"

    available: BluetoothStatus.available
    toggled: BluetoothStatus.enabled
    mainAction: () => {
        Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter?.enabled
    }
    hasMenu: true
}
