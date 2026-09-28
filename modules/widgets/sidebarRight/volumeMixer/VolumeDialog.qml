pragma ComponentBehavior: Bound
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.m3 as M3
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire

M3.Dialog {
    id: root
    property bool isSink: true
    backgroundHeight: 600

    M3.DialogTitle {
        text: root.isSink ? "Audio output" : "Audio input"
    }

    M3.Divider {
        Layout.topMargin: -22
        Layout.leftMargin: 0
        Layout.rightMargin: 0
    }

    VolumeDialogContent {
        isSink: root.isSink
    }

    M3.DialogButtonRow {
        M3.Button {
            variant: "text"
            text: "Details"
            onClicked: {
                Quickshell.execDetached(["bash", "-c", `${Apps.volumeMixer}`]);
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
