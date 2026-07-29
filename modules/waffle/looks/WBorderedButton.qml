import QtQuick
import QtQuick.Controls
import Quickshell
import qs.modules.common
import qs.modules.common.functions
import qs.modules.waffle.looks

WButton {
    id: root

    property color colBorder: Looks.colors.bg2Border
    property color colBorderToggled: Looks.colors.accent

    colBackground: Looks.colors.bg2
    colBackgroundHover: Looks.colors.bg2Hover
    colBackgroundActive: Looks.colors.bg2Active
    border.color: checked ? colBorderToggled : colBorder
    border.width: root.pressed ? 2 : 1
}
