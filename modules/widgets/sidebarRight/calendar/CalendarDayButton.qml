import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.m3 as M3

/**
 * One cell of the month grid: a toggle button whose selected state is today.
 * Days outside the viewed month are drawn as disabled.
 */
M3.Button {
    id: button

    property string day
    property int isToday
    property bool bold

    Layout.fillWidth: false
    Layout.fillHeight: false
    implicitWidth: 38
    implicitHeight: 38
    leftPadding: 0
    rightPadding: 0
    buttonRadius: Appearance.rounding.small

    variant: "text"
    toggleable: true
    selected: isToday === 1
    enabled: isToday !== -1
    text: day
    font.weight: bold ? Font.DemiBold : Font.Normal
}
