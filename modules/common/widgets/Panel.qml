pragma ComponentBehavior: Bound

import qs
import qs.services
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

/**
 * Base panel component that derives open state, IPC target and shortcut
 * from a single panel name.
 */
Scope {
    id: root

    required property string name
    property string target: root.name
    property string description: `Toggle ${root.name}`

    property bool opened: false
    property bool manageIpc: true
    property bool hasToggleShortcut: true
    property string toggleShortcutName: root.name + "Toggle"
    property bool hasOpenCloseShortcuts: false

    signal dismissed()
    signal aboutToOpen()
    signal aboutToClose()

    function open(): void {
        root.aboutToOpen();
        root.opened = true;
    }

    function close(): void {
        root.aboutToClose();
        root.opened = false;
    }

    function toggle(): void {
        if (root.opened)
            root.close();
        else
            root.open();
    }

    Component.onCompleted: {
        try {
            if (root.name && (root.name in GlobalStates)) {
                GlobalStates[root.name] = root;
            }
        } catch (e) {}
    }

    Loader {
        active: root.manageIpc
        sourceComponent: IpcHandler {
            target: root.target

            function open(): void {
                root.open();
            }

            function close(): void {
                root.close();
            }

            function toggle(): void {
                root.toggle();
            }
        }
    }

    Loader {
        active: root.hasToggleShortcut
        sourceComponent: GlobalShortcut {
            name: root.toggleShortcutName
            description: root.description

            onPressed: {
                root.toggle();
            }
        }
    }

    Loader {
        active: root.hasOpenCloseShortcuts
        sourceComponent: Scope {
            GlobalShortcut {
                name: root.name + "Open"
                description: `Opens ${root.name} on press`

                onPressed: {
                    root.open();
                }
            }

            GlobalShortcut {
                name: root.name + "Close"
                description: `Closes ${root.name} on press`

                onPressed: {
                    root.close();
                }
            }
        }
    }
}
