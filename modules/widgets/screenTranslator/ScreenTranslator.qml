pragma ComponentBehavior: Bound
import qs
import qs.modules.common.widgets
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Panel {
    id: root
    name: "screenTranslator"
    manageIpc: false
    hasToggleShortcut: false

    readonly property var currentScreen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? null

    Loader {
        id: translatorLoader
        property var lockedScreen
        active: false
        Connections {
            target: root
            function onOpenedChanged() {
                if (!root.opened) {
                    translatorLoader.active = false;
                } else {
                    translatorLoader.lockedScreen = root.currentScreen;
                    translatorLoader.active = true;
                }
            }
        }

        sourceComponent: ScreenTranslatorPanel {
            screen: translatorLoader.lockedScreen
            onDismiss: root.close()
        }
    }

    function translate() {
        root.open();
    }

    IpcHandler {
        target: "screenTranslator"

        function translate() {
            root.translate();
        }
        function open() {
            root.open();
        }
        function close() {
            root.close();
        }
        function toggle() {
            root.toggle();
        }
    }

    GlobalShortcut {
        name: "screenTranslate"
        description: "Translates screen content"
        onPressed: root.translate()
    }
}
