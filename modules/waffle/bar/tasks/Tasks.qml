import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.modules.common
import qs.modules.waffle.looks
import qs.services

MouseArea {
    id: root

    function showPreviewPopup(appEntry, button) {
        previewPopup.show(appEntry, button);
    }

    Layout.fillHeight: true
    implicitHeight: appRow.implicitHeight
    implicitWidth: appRow.implicitWidth
    hoverEnabled: true

    WListView {
        id: appRow

        orientation: Qt.Horizontal
        spacing: 0
        implicitWidth: contentWidth
        clip: true
        interactive: false

        anchors {
            top: parent.top
            bottom: parent.bottom
        }

        // TODO: Include only apps (and windows) in current workspace only | wait, does that even make sense in a Hyprland workflow?
        model: ScriptModel {
            objectProp: "appId"
            values: TaskbarApps.apps.filter((app) => {
                return app.appId !== "SEPARATOR";
            })
        }

        delegate: TaskAppButton {
            required property var modelData

            appEntry: modelData
            onHoverPreviewRequested: {
                root.showPreviewPopup(appEntry, this);
            }
            onHoverPreviewDismissed: {
                previewPopup.close();
            }
        }

    }

    // Previews popup
    TaskPreview {
        id: previewPopup

        tasksHovered: root.containsMouse
        anchor.window: root.QsWindow.window
    }

    Behavior on implicitWidth {
        animation: Looks.transition.move.createObject(this)
    }

}
