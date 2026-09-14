import QtQuick
import qs.modules.common
import qs.modules.common.functions

CircularProgress {
    id: root

    property string icon: ""
    property real iconSize: Appearance.font.pixelSize.small
    property real iconFill: 0
    property color iconColor: colPrimary
    property real trackTransparency: 0.65

    drainClockwise: true
    colSecondary: ColorUtils.transparentize(colPrimary, trackTransparency)

    MaterialSymbol {
        anchors.centerIn: parent
        visible: root.icon.length > 0
        text: root.icon
        iconSize: root.iconSize
        fill: root.iconFill
        color: root.iconColor
    }

    Behavior on colPrimary {
        enabled: root.enableAnimation
        animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
    }

    Behavior on iconColor {
        enabled: root.enableAnimation
        animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
    }
}
