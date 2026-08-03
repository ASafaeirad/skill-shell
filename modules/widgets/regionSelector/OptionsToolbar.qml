pragma ComponentBehavior: Bound
import qs
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

// Options toolbar
Toolbar {
    id: root

    // Use a synchronizer on this
    property var action
    // Whether the current action is one of the switchable capture modes
    property bool captureModes: false
    // Signals
    signal dismiss()
    signal captureModeSelected(int index)

    ToolbarTabBar {
        id: captureModeTabBar
        tabButtonList: [
            {"icon": "photo_camera", "name": "Shot"},
            {"icon": "videocam", "name": "Record"},
            {"icon": "mic", "name": "Record + audio"}
        ]
        currentIndex: switch (root.action) {
        case RegionSelection.SnipAction.Record:
            return 1;
        case RegionSelection.SnipAction.RecordWithSound:
            return 2;
        default:
            return 0;
        }
        // Guarded: this also fires while the tab bar initializes, which would otherwise
        // knock a search/ocr overlay into screenshot mode
        onCurrentIndexChanged: if (root.captureModes) root.captureModeSelected(currentIndex)
    }
}
