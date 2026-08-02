import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.modules.common
import qs.modules.widgets.overlay
import qs.services

StyledOverlayWidget {
    id: root

    title: "Notes"
    showCenterButton: true

    contentItem: NotesContent {
        radius: root.contentRadius
        isClickthrough: root.clickthrough
    }

}
