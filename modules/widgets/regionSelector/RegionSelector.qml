pragma ComponentBehavior: Bound
import qs
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Panel {
    id: root
    name: "region"
    target: "region"
    manageIpc: false
    hasToggleShortcut: false

    function dismiss() {
        root.close();
    }

    Component.onCompleted: {
        GlobalStates.regionSelector = root;
    }

    property var action: RegionSelection.SnipAction.Copy

    Variants {
        model: Quickshell.screens
        delegate: Loader {
            id: regionSelectorLoader
            required property var modelData
            active: root.opened

            sourceComponent: RegionSelection {
                screen: regionSelectorLoader.modelData
                onDismiss: root.dismiss()
                action: root.action
            }
        }
    }

    // The one entry point for screenshot, record and record with sound.
    // Opens in screenshot mode; the toolbar (or Tab) switches mode before the region is picked.
    // If a recording is running, this stops it instead of opening.
    function capture() {
        root.action = RegionSelection.SnipAction.Copy
        // If already open then re-trigger so a running recording gets stopped
        if (root.opened) root.opened = false
        root.open()
    }

    function search() {
        root.action = RegionSelection.SnipAction.Search
        root.open()
    }

    function ocr() {
        root.action = RegionSelection.SnipAction.CharRecognition
        root.open()
    }

    Connections {
        target: GlobalStates

        function onRegionCaptureRequested() {
            root.capture()
        }

        function onRegionSearchRequested() {
            root.search()
        }
    }

    IpcHandler {
        target: "region"

        function capture() {
            root.capture()
        }
        function search() {
            root.search()
        }
        function ocr() {
            root.ocr()
        }
        function open() {
            root.capture()
        }
        function close() {
            root.close()
        }
        function toggle() {
            root.toggle()
        }
    }

    GlobalShortcut {
        name: "regionCapture"
        description: "Screenshots or records the selected region, switchable in the overlay"
        onPressed: root.capture()
    }
    GlobalShortcut {
        name: "regionSearch"
        description: "Searches the selected region"
        onPressed: root.search()
    }
    GlobalShortcut {
        name: "regionOcr"
        description: "Recognizes text in the selected region"
        onPressed: root.ocr()
    }
}
