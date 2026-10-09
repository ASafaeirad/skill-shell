import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.m3 as M3
import qs.services
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire

Item {
    id: root
    required property PwNode node
    PwObjectTracker {
        objects: [root.node]
    }

    implicitHeight: rowLayout.implicitHeight

    RowLayout {
        id: rowLayout
        anchors.fill: parent
        spacing: 6

        M3.IconButton {
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            variant: "standard"
            materialIcon: root.node?.isSink ? "volume_off" : "mic_off"
            iconSource: {
                if (root.node?.audio.muted)
                    return "";
                let icon = AppSearch.guessIcon(root.node?.properties["application.icon-name"] ?? "");
                if (AppSearch.iconExists(icon))
                    return Quickshell.iconPath(icon, "image-missing");
                icon = AppSearch.guessIcon(root.node?.properties["node.name"] ?? "");
                return Quickshell.iconPath(icon, "image-missing");
            }
            tooltip: root.node?.audio.muted ? "Click to unmute" : "Click to mute"
            onClicked: root.node.audio.muted = !root.node.audio.muted
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: -4

            StyledText {
                Layout.fillWidth: true
                font.pixelSize: Appearance.font.pixelSize.small
                color: Appearance.colors.colSubtext
                elide: Text.ElideRight
                text: {
                    // application.name -> description -> name
                    const app = Audio.appNodeDisplayName(root.node);
                    const media = root.node.properties["media.name"];
                    return media != undefined ? `${app} • ${media}` : app;
                }
            }

            M3.Slider {
                id: slider
                value: root.node?.audio.volume ?? 0
                onMoved: root.node.audio.volume = value
                configuration: M3.Slider.Configuration.S
            }
        }
    }
}
