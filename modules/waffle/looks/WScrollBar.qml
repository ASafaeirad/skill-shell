import QtQuick
import QtQuick.Controls
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

ScrollBar {
    id: root

    property color color: Looks.colors.controlBg

    policy: ScrollBar.AsNeeded
    active: hovered || pressed

    contentItem: Rectangle {
        implicitWidth: root.active ? 4 : 2
        implicitHeight: root.visualSize
        radius: 9999
        color: root.color
        opacity: root.policy === ScrollBar.AlwaysOn || (root.active && root.size < 1) ? 0.5 : 0

        Behavior on opacity {
            animation: Looks.transition.opacity.createObject(this)
        }

    }

}
