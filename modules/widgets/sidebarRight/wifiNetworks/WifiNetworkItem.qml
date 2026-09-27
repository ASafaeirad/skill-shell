import qs
import qs.modules.common
import qs.modules.common.m3 as M3
import qs.services
import qs.services.network
import QtQuick
import QtQuick.Layouts

/**
 * One network in the Wi-Fi dialog: an M3 list item, with the password prompt and the
 * captive-portal action expanding underneath it.
 */
Item {
    id: root

    required property WifiAccessPoint wifiNetwork
    // NetworkManager is bringing this network up; the row can't be clicked again yet.
    readonly property bool connecting: Network.wifiConnectTarget === root.wifiNetwork && !(root.wifiNetwork?.active ?? false)
    // Connected, or waiting for its password: the row is the subject, not a target.
    readonly property bool active: (root.wifiNetwork?.askingPassword || root.wifiNetwork?.active) ?? false
    readonly property int strength: root.wifiNetwork?.strength ?? 0
    readonly property string signalIcon: root.strength > 80 ? "signal_wifi_4_bar" : root.strength > 60 ? "network_wifi_3_bar" : root.strength > 40 ? "network_wifi_2_bar" : root.strength > 20 ? "network_wifi_1_bar" : "signal_wifi_0_bar"
    // Only secured or connected networks carry a trailing icon, as before.
    readonly property string statusIcon: {
        if (!((root.wifiNetwork?.isSecure || root.wifiNetwork?.active) ?? false))
            return "";
        if (root.wifiNetwork?.active)
            return "check";
        return root.connecting ? "settings_ethernet" : "lock";
    }

    implicitHeight: content.implicitHeight
    height: implicitHeight
    clip: true

    Behavior on height {
        animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
    }

    ColumnLayout {
        id: content

        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 0

        M3.ListItem {
            Layout.fillWidth: true
            enabled: !root.connecting
            interactive: !root.active
            leadingIcon: root.signalIcon
            text: root.wifiNetwork?.ssid ?? "Unknown"
            trailingIcon: root.statusIcon
            onClicked: Network.connectToWifiNetwork(root.wifiNetwork)
        }

        ColumnLayout {
            id: passwordPrompt

            visible: root.wifiNetwork?.askingPassword ?? false
            Layout.fillWidth: true
            Layout.leftMargin: Appearance.spacing.xl
            Layout.rightMargin: Appearance.spacing.xl
            Layout.bottomMargin: Appearance.spacing.m
            spacing: Appearance.spacing.s

            M3.TextField {
                id: passwordField

                Layout.fillWidth: true
                placeholderText: "Password"
                echoMode: TextInput.Password
                inputMethodHints: Qt.ImhSensitiveData
                onAccepted: Network.changePassword(root.wifiNetwork, passwordField.text)
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacing.s

                Item {
                    Layout.fillWidth: true
                }

                M3.Button {
                    variant: "text"
                    text: "Cancel"
                    onClicked: root.wifiNetwork.askingPassword = false
                }

                M3.Button {
                    variant: "filled"
                    text: "Connect"
                    onClicked: Network.changePassword(root.wifiNetwork, passwordField.text)
                }
            }
        }

        M3.Button {
            visible: (root.wifiNetwork?.active && (root.wifiNetwork?.security ?? "").trim().length === 0) ?? false
            Layout.fillWidth: true
            Layout.leftMargin: Appearance.spacing.xl
            Layout.rightMargin: Appearance.spacing.xl
            Layout.bottomMargin: Appearance.spacing.m
            variant: "tonal"
            text: "Open network portal"
            onClicked: {
                Network.openPublicWifiPortal();
                GlobalStates.sidebarRight?.close();
            }
        }
    }
}
