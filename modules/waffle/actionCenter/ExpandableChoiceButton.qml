import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.waffle.actionCenter
import qs.modules.waffle.looks
import qs.services
import qs.services.network

WChoiceButton {
    id: root

    property bool expanded: false

    checked: expanded
    clip: true
    horizontalPadding: 12
    verticalPadding: 6
    animateChoiceHighlight: false
    onClicked: expanded = !expanded

    Behavior on implicitHeight {
        animation: Looks.transition.resize.createObject(this)
    }

}
