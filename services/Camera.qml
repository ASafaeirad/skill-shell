pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common

Singleton {
    id: root

    readonly property string helper: Directories.scriptPath + "/camera/privacy.py"
    property bool blocked: false
    property bool available: false
    readonly property bool busy: changeProcess.running
    property string error: ""

    function refresh() {
        if (!statusProcess.running && !root.busy)
            statusProcess.running = true;
    }

    function toggle() {
        if (root.busy || !root.available) return;
        root.error = "";
        changeProcess.command = ["pkexec", "/usr/bin/python3", root.helper, root.blocked ? "unblock" : "block"];
        changeProcess.running = true;
    }

    Component.onCompleted: refresh()

    Timer {
        interval: 2000
        repeat: true
        running: true
        onTriggered: root.refresh()
    }

    Process {
        id: statusProcess
        command: ["/usr/bin/python3", root.helper, "status"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const state = JSON.parse(text);
                    root.blocked = state.blocked;
                    root.available = state.available;
                } catch (error) {
                    root.available = false;
                }
            }
        }
        onExited: (code, status) => {
            if (code !== 0) root.available = false;
        }
    }

    Process {
        id: changeProcess
        stderr: StdioCollector {
            onStreamFinished: if (text.trim()) root.error = text.trim()
        }
        onExited: (code, status) => {
            if (code !== 0 && !root.error)
                root.error = "Camera access was not changed. Authentication may have been cancelled.";
            root.refresh();
        }
    }
}
