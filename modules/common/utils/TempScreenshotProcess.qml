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
    property bool keepCursorHidden: false
    // RegionSelection saves its native frozen frame instead of capturing twice.
    property bool captureToFile: true
    property bool cursorRestored: false
    readonly property bool cursorHidden: keepCursorHidden && !running && !cursorRestored

    function restoreCursor() {
        if (!keepCursorHidden || cursorRestored) return;
        cursorRestored = true;
        Quickshell.execDetached(["hyprctl", "eval", "hl.config({ cursor = { invisible = false } })"]);
    }

    running: true
    command: ["bash", "-c", `
        cursorWasInvisible="$(hyprctl -j getoption cursor.invisible | jq -r '.bool // false')"
        hyprctl eval 'hl.config({ cursor = { invisible = true } })' || exit 1
        sleep ${Appearance.animation.elementMoveFast.duration / 1000}
        mkdir -p '${StringUtils.shellSingleQuoteEscape(screenshotDir)}' \
            ${captureToFile ? `&& timeout --kill-after=1s 3s grim -o '${StringUtils.shellSingleQuoteEscape(screen.name)}' '${StringUtils.shellSingleQuoteEscape(screenshotPath)}'` : ""}
        captureStatus=$?
        if [[ '${keepCursorHidden}' != 'true' || "$captureStatus" != 0 ]]; then
            hyprctl eval "hl.config({ cursor = { invisible = $cursorWasInvisible } })"
        fi
        exit "$captureStatus"
    `]
}
