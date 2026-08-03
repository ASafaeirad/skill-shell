pragma ComponentBehavior: Bound
import qs
import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Scope {
    id: root

    function dismiss() {
        GlobalStates.regionSelectorOpen = false
    }

    property var action: RegionSelection.SnipAction.Copy

    Variants {
        model: Quickshell.screens
        delegate: Loader {
            id: regionSelectorLoader
            required property var modelData
            active: GlobalStates.regionSelectorOpen

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
        if (GlobalStates.regionSelectorOpen) GlobalStates.regionSelectorOpen = false
        GlobalStates.regionSelectorOpen = true
    }

    function search() {
        root.action = RegionSelection.SnipAction.Search
        GlobalStates.regionSelectorOpen = true
    }

    function ocr() {
        root.action = RegionSelection.SnipAction.CharRecognition
        GlobalStates.regionSelectorOpen = true
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
