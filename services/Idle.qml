import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.modules.common
pragma Singleton

/**
 * A nice wrapper for date and time strings.
 */
Singleton {
    id: root

    property alias inhibit: idleInhibitor.enabled

    function toggleInhibit(active = null) {
        if (active !== null)
            root.inhibit = active;
        else
            root.inhibit = !root.inhibit;
        Persistent.states.idle.inhibit = root.inhibit;
    }

    inhibit: false

    Connections {
        function onReadyChanged() {
            if (!Persistent.isNewHyprlandInstance)
                root.inhibit = Persistent.states.idle.inhibit;
            else
                Persistent.states.idle.inhibit = root.inhibit;
        }

        target: Persistent
    }

    IdleInhibitor {
        id: idleInhibitor

        window: PanelWindow {
            // Inhibitor requires a "visible" surface
            // Actually not lol
            implicitWidth: 0
            implicitHeight: 0
            color: "transparent"

            // Just in case...
            anchors {
                right: true
                bottom: true
            }

            // Make it not interactable
            mask: Region {
                item: null
            }

        }

    }

}
