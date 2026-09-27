import qs.modules.common
import qs.modules.common.m3 as M3
import qs.services
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    required property var device
    property bool expanded: false

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
            leadingIcon: Icons.getBluetoothDeviceMaterialSymbol(root.device?.icon || "")
            text: root.device?.name || "Unknown device"
            supportingText: {
                if (!root.device?.paired) return "";
                let statusText = root.device?.connected ? "Connected" : "Paired";
                if (!root.device?.batteryAvailable) return statusText;
                return `${statusText} • ${Math.round(root.device?.battery * 100)}%`;
            }
            trailingIcon: root.expanded ? "keyboard_arrow_up" : "keyboard_arrow_down"
            onClicked: root.expanded = !root.expanded
            altAction: () => root.expanded = !root.expanded
        }

        RowLayout {
            visible: root.expanded
            Layout.fillWidth: true
            Layout.leftMargin: Appearance.spacing.xl
            Layout.rightMargin: Appearance.spacing.xl
            Layout.bottomMargin: Appearance.spacing.m
            spacing: Appearance.spacing.s

            Item { Layout.fillWidth: true }

            M3.Button {
                variant: root.device?.paired ? "outlined" : "text"
                text: root.device?.paired ? "Forget" : "Always connect"
                onClicked: {
                    if (root.device?.paired) {
                        root.device?.forget();
                    } else {
                        root.device?.pair();
                    }
                }
            }

            M3.Button {
                variant: "filled"
                text: root.device?.connected ? "Disconnect" : "Connect"
                onClicked: {
                    if (root.device?.connected) {
                        root.device.disconnect();
                    } else {
                        root.device.connect();
                    }
                }
            }
        }
    }
}
