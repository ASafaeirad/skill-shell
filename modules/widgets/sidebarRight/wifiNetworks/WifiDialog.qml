import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import qs.services.network

WindowDialog {
    id: root

    backgroundHeight: 600

    WindowDialogTitle {
        text: "Connect to Wi-Fi"
    }

    WindowDialogSeparator {
        visible: !Network.wifiScanning
    }

    StyledIndeterminateProgressBar {
        visible: Network.wifiScanning
        Layout.fillWidth: true
        Layout.topMargin: -8
        Layout.bottomMargin: -8
        Layout.leftMargin: -Appearance.rounding.large
        Layout.rightMargin: -Appearance.rounding.large
    }

    ListView {
        Layout.fillHeight: true
        Layout.fillWidth: true
        Layout.topMargin: -15
        Layout.bottomMargin: -16
        Layout.leftMargin: -Appearance.rounding.large
        Layout.rightMargin: -Appearance.rounding.large
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

    WindowDialogSeparator {
    }

    WindowDialogButtonRow {
        DialogButton {
            buttonText: "Details"
            onClicked: {
                Quickshell.execDetached(["bash", "-c", `${Network.ethernet ? Apps.networkEthernet : Apps.network}`]);
                GlobalStates.sidebarRightOpen = false;
            }
        }

        Item {
            Layout.fillWidth: true
        }

        DialogButton {
            buttonText: "Done"
            onClicked: root.dismiss()
        }

    }

}
