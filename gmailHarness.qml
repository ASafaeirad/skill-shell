import QtQuick
import Quickshell
import qs.services

ShellRoot {
    Component.onCompleted: console.log("[harness] gmail accounts:", Gmail.configuredAccounts.length)
}
