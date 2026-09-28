import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.modules.common
import qs.modules.common.m3 as M3
import qs.modules.common.widgets
import qs.services
import qs.services.network

M3.Dialog {
    id: root

    backgroundHeight: 600

    M3.DialogTitle {
        text: "Connect to Wi-Fi"
    }

    M3.Divider {
        visible: !Network.wifiScanning
        Layout.leftMargin: -Appearance.spacing.xl
        Layout.rightMargin: -Appearance.spacing.xl
        Layout.topMargin: -Appearance.spacing.s
        Layout.bottomMargin: -Appearance.spacing.s
    }

    M3.LinearProgressIndicator {
        indeterminate: true
        visible: Network.wifiScanning
        Layout.fillWidth: true
        Layout.topMargin: -Appearance.spacing.s
        Layout.bottomMargin: -Appearance.spacing.s
        Layout.leftMargin: -Appearance.spacing.xl
        Layout.rightMargin: -Appearance.spacing.xl
    }

    ListView {
        Layout.fillHeight: true
        Layout.fillWidth: true
        Layout.topMargin: -15
        Layout.bottomMargin: -16
        Layout.leftMargin: -Appearance.spacing.xl
        Layout.rightMargin: -Appearance.spacing.xl
        clip: true
        spacing: 0

        model: ScriptModel {
            values: Network.friendlyWifiNetworks
        }

        delegate: WifiNetworkItem {
            required property WifiAccessPoint modelData

            wifiNetwork: modelData
            width: ListView.view.width
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
                Quickshell.execDetached(["bash", "-c", `${Network.ethernet ? Apps.networkEthernet : Apps.network}`]);
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
