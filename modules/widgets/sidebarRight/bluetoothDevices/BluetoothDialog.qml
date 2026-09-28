import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.m3 as M3
import qs.modules.common.functions
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell.Io
import Quickshell.Bluetooth
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

M3.Dialog {
    id: root
    backgroundHeight: 600

    M3.DialogTitle {
        text: "Bluetooth devices"
    }
    M3.Divider {
        visible: !(Bluetooth.defaultAdapter?.discovering ?? false)
        Layout.leftMargin: -Appearance.spacing.xl
        Layout.rightMargin: -Appearance.spacing.xl
        Layout.topMargin: -Appearance.spacing.s
        Layout.bottomMargin: -Appearance.spacing.s
    }
    M3.LinearProgressIndicator {
        indeterminate: true
        visible: Bluetooth.defaultAdapter?.discovering ?? false
        Layout.fillWidth: true
        Layout.topMargin: -8
        Layout.bottomMargin: -8
        Layout.leftMargin: -Appearance.spacing.xl
        Layout.rightMargin: -Appearance.spacing.xl
    }
    StyledListView {
        Layout.fillHeight: true
        Layout.fillWidth: true
        Layout.topMargin: -15
        Layout.bottomMargin: -16
        Layout.leftMargin: -Appearance.spacing.xl
        Layout.rightMargin: -Appearance.spacing.xl

        clip: true
        spacing: 0
        animateAppearance: false

        model: ScriptModel {
            values: BluetoothStatus.friendlyDeviceList
        }
        delegate: BluetoothDeviceItem {
            required property BluetoothDevice modelData
            device: modelData
            anchors {
                left: parent?.left
                right: parent?.right
            }
        }
    }
    M3.Divider {
        Layout.leftMargin: -Appearance.spacing.xl
        Layout.rightMargin: -Appearance.spacing.xl
        Layout.topMargin: -Appearance.spacing.s
        Layout.bottomMargin: -Appearance.spacing.s
    }
    M3.DialogButtonRow {
        M3.Button {
            variant: "text"
            text: "Details"
            onClicked: {
                Quickshell.execDetached(["bash", "-c", `${Apps.bluetooth}`]);
                GlobalStates.sidebarRight?.close();
            }
        }

        Item {
            Layout.fillWidth: true
        }

        M3.Button {
            variant: "text"
            text: "Done"
            onClicked: root.dismiss()
        }
    }
}
