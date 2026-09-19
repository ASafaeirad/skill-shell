import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import qs.services
import qs.modules.common.widgets

Scope {
    id: root

    function open() {
        dialog.open();
        PassService.refresh();
    }

    function close() {
        dialog.close();
        PassService.clearSecrets();
    }

    function toggle() {
        if (dialog.opened)
            root.close();
        else
            root.open();
    }

    OverlayDialog {
        id: dialog

        stateKey: "passOpen"
        layerNamespace: "quickshell:pass"
        keyboardFocus: WlrKeyboardFocus.Exclusive
        onDismissed: root.close()

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

    GlobalShortcut {
        name: "passToggle"
        description: "Toggle password helper"
        onPressed: root.toggle()
    }
}
