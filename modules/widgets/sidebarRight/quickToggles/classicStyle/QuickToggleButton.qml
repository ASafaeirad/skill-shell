import QtQuick
import qs.modules.common
import qs.modules.common.models.quickToggles
import qs.modules.common.widgets

GroupButton {
    id: button

    property QuickToggleModel toggleModel: null
    property string buttonIcon: toggleModel?.icon ?? ""
    property string tooltipText: toggleModel?.tooltipText ?? ""

    baseWidth: 40
    baseHeight: 40
    clickedWidth: baseWidth + 20
    visible: toggleModel?.available ?? true
    toggled: toggleModel?.toggled ?? false
    buttonRadius: (altAction && toggled) ? Appearance?.rounding.normal : Math.min(baseHeight, baseWidth) / 2
    buttonRadiusPressed: Appearance?.rounding?.small

    onClicked: {
        if (toggleModel?.mainAction) {
            toggleModel.mainAction();
        }
    }
    altAction: toggleModel?.altAction ?? null

    contentItem: MaterialSymbol {
        anchors.centerIn: parent
        iconSize: 22
        fill: button.toggled ? 1 : 0
        color: button.toggled ? Appearance.m3colors.m3onPrimary : Appearance.colors.colOnLayer1
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        text: button.buttonIcon

        Behavior on color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }
    }

    StyledToolTip {
        extraVisibleCondition: button.tooltipText !== ""
        text: button.tooltipText
    }
}
