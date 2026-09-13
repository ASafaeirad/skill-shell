import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import qs
import qs.services
import qs.modules.common.widgets

Scope {
    id: root

    property bool closing: false

    function open() {
        root.closing = false;
        GlobalStates.passOpen = true;
        PassService.refresh();
    }

    function close() {
        const content = panelLoader.item?.passContent ?? null;
        if (content && GlobalStates.passOpen) {
            root.closing = true;
            content.animateOut();
        }
        GlobalStates.passOpen = false;
        PassService.clearSecrets();
    }

    function toggle() {
        if (GlobalStates.passOpen)
            root.close();
        else
            root.open();
    }

    Loader {
        id: panelLoader
        active: GlobalStates.passOpen || root.closing

        sourceComponent: OverlayDialogWindow {
            readonly property alias passContent: content
            layerNamespace: "quickshell:pass"
            keyboardFocus: WlrKeyboardFocus.Exclusive
            scrimOpacity: content.opacity
            onDismissed: root.close()

            PassContent {
                id: content
                anchors.centerIn: parent
                onCloseRequested: root.close()
                onCloseFinished: root.closing = false
            }
        }
    }

    Connections {
        target: GlobalStates
        function onPassOpenChanged() {
            if (GlobalStates.passOpen && root.closing) {
                root.closing = false;
                panelLoader.item?.passContent?.animateIn();
            }
        }
    }

    Connections {
        target: PassService
        function onCloseRequested() {
            root.close();
        }
    }

    IpcHandler {
        target: "pass"
        function toggle(): void {
        root.toggle();
    }
        function open(): void {
                             root.open();
                         }
        function close(): void {
        root.close();
    }
        function refresh(): void {
                                PassService.refresh();
                            }
    }

    GlobalShortcut {
        name: "passToggle"
        description: "Toggle password helper"
        onPressed: root.toggle()
    }
}
