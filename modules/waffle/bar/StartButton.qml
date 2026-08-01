import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs
import qs.modules.common
import qs.modules.waffle.looks
import qs.services

// TODO: Replace the icon with QMLized svg (with /usr/lib/qt6/bin/svgtoqml) for proper micro-animation
AppButton {
    id: root

    leftInset: Config.options.waffles.bar.leftAlignApps ? 12 : 0
    iconName: down ? "start-here-pressed" : "start-here"
    checked: GlobalStates.searchOpen && LauncherSearch.query === ""
    onClicked: {
        GlobalStates.searchOpen = !GlobalStates.searchOpen;
    }
    altAction: () => {
        contextMenu.active = true;
    }

    BarToolTip {
        id: tooltip

        text: "Start"
        extraVisibleCondition: root.shouldShowTooltip
    }

    BarMenu {
        id: contextMenu

        model: [{
            "text": "Terminal",
            "action": () => {
                Quickshell.execDetached(["bash", "-c", Config.options.apps.terminal]);
            }
        }, {
            "text": "Task Manager",
            "action": () => {
                Quickshell.execDetached(["bash", "-c", Config.options.apps.taskManager]);
            }
        }, {
            "text": "Settings",
            "action": () => {
                Quickshell.execDetached(["qs", "-p", Quickshell.shellPath("settings.qml")]);
            }
        }, {
            "text": "File Explorer",
            "action": () => {
                Qt.openUrlExternally(Directories.home);
            }
        }, {
            "text": "Search",
            "action": () => {
                Quickshell.execDetached(["qs", "-p", Quickshell.shellPath(""), "ipc", "call", "overview", "toggle"]);
            }
        }]
    }

}
