import QtQuick
import qs.modules.common
import qs.modules.common.models.quickToggles
import qs.modules.common.m3 as M3

M3.IconButton {
    id: button

    property QuickToggleModel toggleModel: null
    property string buttonIcon: ""
    property bool toggled: false
    property real baseWidth: Appearance.sizes.m3IconButtonSize
    property real baseHeight: Appearance.sizes.m3IconButtonSize
    property real radius: buttonRadius

    implicitWidth: baseWidth
    implicitHeight: baseHeight
    visible: toggleModel?.available ?? true
    variant: "filled"
    toggleable: true
    selected: toggleModel?.toggled ?? toggled
    materialIcon: toggleModel?.icon ?? buttonIcon
    tooltip: toggleModel?.tooltipText ?? ""

    onClicked: {
        if (toggleModel?.mainAction) {
            toggleModel.mainAction();
        }
    }
    altAction: toggleModel?.altAction ?? null

}
