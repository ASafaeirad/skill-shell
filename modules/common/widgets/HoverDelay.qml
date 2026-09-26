import qs.modules.common
import QtQuick

Timer {
    id: root

    property bool hovered: false
    property bool ready: false

    interval: Appearance.animation.hoverOpenDelay
    repeat: false
    running: hovered && !ready

    onHoveredChanged: {
        if (!hovered)
            ready = false;
    }
    onTriggered: ready = true
}
