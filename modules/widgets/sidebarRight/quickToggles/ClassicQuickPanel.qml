import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth
import qs.modules.common
import qs.modules.common.m3 as M3
import qs.modules.common.widgets
import qs.modules.widgets.sidebarRight.quickToggles.classicStyle
import qs.services

AbstractQuickPanel {
    id: root

    Layout.alignment: Qt.AlignHCenter
    implicitWidth: buttonGroup.implicitWidth
    implicitHeight: buttonGroup.implicitHeight
    color: "transparent"

    M3.ButtonGroup {
        id: buttonGroup

        spacing: 5
        padding: 5

        NetworkToggle {
            altAction: () => {
                root.openWifiDialog();
            }
        }

        BluetoothToggle {
            altAction: () => {
                root.openBluetoothDialog();
            }
        }

        NightLight {
        }

        GameMode {
        }

        IdleInhibitor {
        }

        EasyEffectsToggle {
        }

    }

}
