import QtQuick
import Quickshell
import Quickshell.Bluetooth
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.models.quickToggles
import qs.modules.common.widgets
import qs.services

AndroidQuickToggleButton {
    id: root

    toggleModel: BluetoothToggle {
    }

}
