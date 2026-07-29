import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common
import qs.modules.common.functions

Process {
    id: screenshotProc

    property string screenshotDir: Directories.screenshotTemp
    required property ShellScreen screen
    property string screenshotPath: `${screenshotDir}/image-${screen.name}`

    running: true
    command: ["bash", "-c", `mkdir -p '${StringUtils.shellSingleQuoteEscape(screenshotDir)}' && grim -o '${StringUtils.shellSingleQuoteEscape(screen.name)}' '${StringUtils.shellSingleQuoteEscape(screenshotPath)}'`]
}
