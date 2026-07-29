import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

// Window content with navigation rail and content pane
ColumnLayout {
    id: root

    property bool expanded: true
    property int currentIndex: 0

    spacing: 5
}
