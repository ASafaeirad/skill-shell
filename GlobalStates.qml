import qs.modules.common
import qs.services
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
pragma Singleton
pragma ComponentBehavior: Bound

Singleton {
    id: root

    // Panel references
    property var bar: null
    property var keyDisplay: null
    property var mediaControls: null
    property var osdBrightness: null
    property var osdVolume: null
    property var overlay: null
    property var pass: null
    property var pinentry: null
    property var popup: null
    property var region: null
    property var regionSelector: null
    property var search: null
    property var overview: null
    property var selector: null
    property var screenTranslator: null
    property var screenZoom: null
    property var session: null
    property var sidebarRight: null
    property var wallpaperSelector: null

    // Shared state
    property Item mediaBarItem: null
    property real mediaBarX: -1
    property real mediaBarWidth: 0
    property bool screenLocked: false
    property bool screenLockContainsCharacters: false
    property bool screenUnlockFailed: false
    property bool superDown: false
    property bool superReleaseMightTrigger: true
    property bool workspaceShowNumbers: false

    signal regionCaptureRequested()
    signal regionSearchRequested()

    GlobalShortcut {
        name: "workspaceNumber"
        description: "Hold to show workspace numbers, release to show icons"

        onPressed: {
            root.superDown = true
        }
        onReleased: {
            root.superDown = false
        }
    }
}
