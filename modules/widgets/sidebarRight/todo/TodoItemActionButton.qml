import QtQuick
import qs.modules.common
import qs.modules.common.widgets

RippleButton {
    id: button

    property string buttonText: ""
    property string tooltipText: ""

    implicitHeight: 30
    implicitWidth: implicitHeight
    buttonRadius: Appearance.rounding.small

    StyledToolTip {
        text: tooltipText
        extraVisibleCondition: tooltipText.length > 0
    }

    Behavior on implicitWidth {
        SmoothedAnimation {
            velocity: Appearance.animation.elementMove.velocity
        }

    }

    contentItem: StyledText {
        text: buttonText
        horizontalAlignment: Text.AlignHCenter
        font.pixelSize: Appearance.font.pixelSize.larger
        color: Appearance.colors.colOnLayer1
    }

}
