import qs.services
import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Wayland

/**
 * The fullscreen overlay layer shared by the script-driven dialogs (selector,
 * pinentry, text popup): a transparent layershell window covering the screen,
 * a scrim that dims what's behind and dismisses on an outside click, and a
 * focused content item to hold the dialog card.
 *
 * Instantiate from a Loader/Variants and handle dismissed() to close.
 */
PanelWindow {
    id: root

    default property alias contentData: contentItem.data

    property string layerNamespace: "quickshell:overlayDialog"
    property var keyboardFocus: WlrKeyboardFocus.OnDemand
    // The exit animation keeps the window mapped after the dialog closes.
    // Release keyboard focus and the shared grab before that window is unloaded.
    property bool inputActive: true
    // Fade the scrim together with the card; bind to the card's opacity.
    property real scrimOpacity: 1
    // Also dismiss when something else in the shell grabs focus.
    property bool dismissOnFocusGrab: true

    signal dismissed()

    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.namespace: root.layerNamespace
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.inputActive ? root.keyboardFocus : WlrKeyboardFocus.None

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    function syncFocusGrab(): void {
        if (root.inputActive && root.dismissOnFocusGrab)
            GlobalFocusGrab.addDismissable(root);
        else
            GlobalFocusGrab.removeDismissable(root);
    }

    onInputActiveChanged: root.syncFocusGrab()
    onDismissOnFocusGrabChanged: root.syncFocusGrab()
    Component.onCompleted: root.syncFocusGrab()
    Component.onDestruction: GlobalFocusGrab.removeDismissable(root)

    Connections {
        target: GlobalFocusGrab
        enabled: root.inputActive && root.dismissOnFocusGrab
        function onDismissed() {
            root.dismissed();
        }
    }

    // Dim everything behind the dialog and dismiss on an outside click.
    Rectangle {
        anchors.fill: parent
        color: Appearance.colors.colScrim
        opacity: root.scrimOpacity

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            onClicked: root.dismissed()
        }
    }

    Item {
        id: contentItem

        anchors.fill: parent
        focus: true
    }
}
