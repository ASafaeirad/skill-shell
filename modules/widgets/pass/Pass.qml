import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import qs.services
import qs.modules.common.widgets
import qs.modules.common.m3 as M3

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

    M3.DialogOverlay {
        id: dialog

        layerNamespace: "quickshell:pass"
        // While an entry is decrypting, gpg may raise the pinentry dialog.
        // Let it take the keyboard; Exclusive comes back once the load ends.
        keyboardFocus: PassService.loading ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.Exclusive
        onDismissed: {
            // The pinentry window clears the shared focus grab, which lands
            // here. Closing now would kill `pass show` and drop the pending
            // copy, so stay open until the unlock finishes or fails.
            if (PassService.loading)
                return;
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
