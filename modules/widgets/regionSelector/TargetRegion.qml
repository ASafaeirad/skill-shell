pragma ComponentBehavior: Bound
import qs.modules.common
import QtQuick

Rectangle {
    id: root
    required property var clientDimensions

    property bool targeted: false
    property color borderColor
    property color fillColor: "transparent"
    z: 2
    color: fillColor
    border.color: borderColor
    border.width: targeted ? 4 : 2
    radius: 4

    Behavior on color {
        animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
    }

    visible: opacity > 0
    Behavior on opacity {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }
    x: clientDimensions.at[0]
    y: clientDimensions.at[1]
    width: clientDimensions.size[0]
    height: clientDimensions.size[1]
}
