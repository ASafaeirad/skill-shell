import QtQuick
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

RippleButton {
    id: root

    property bool active: false

    horizontalPadding: Appearance.rounding.large
    verticalPadding: 12
    clip: true
    pointingHandCursor: !active
    implicitWidth: contentItem.implicitWidth + horizontalPadding * 2
    implicitHeight: contentItem.implicitHeight + verticalPadding * 2
    colBackground: ColorUtils.transparentize(Appearance.colors.colLayer3)
    colBackgroundHover: active ? colBackground : Appearance.colors.colLayer3Hover
    colRipple: Appearance.colors.colLayer3Active
    buttonRadius: 0

    Behavior on implicitHeight {
        animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
    }

}
