import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import qs.services
import qs.modules.common.widgets

Panel {
    id: root
    name: "pass"
    description: "Toggle password helper"
    manageIpc: false

    function open(): void {
        PassService.cancelAutotype();
        root.opened = true;
        dialog.open();
        PassService.refresh();
    }

    function close(): void {
        dialog.close();
        root.opened = false;
        PassService.clearSecrets();
    }

    function toggle(): void {
        if (dialog.opened)
            root.close();
        else
            root.open();
    }

    OverlayDialog {
        id: dialog

        layerNamespace: "quickshell:pass"
        keyboardFocus: WlrKeyboardFocus.Exclusive
        onDismissed: {
            PassService.cancelAutotype();
            root.close();
        }
        onCloseFinished: PassService.triggerAutotype()

        PassContent {
            onCloseRequested: root.close()
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
}
