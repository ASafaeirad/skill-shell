import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.m3 as M3

/**
 * One cell of the month grid: a square toggle button whose selected state is
 * today. Days outside the viewed month are drawn as disabled.
 */
M3.Button {
    property string day
    property int isToday

    Layout.fillWidth: false
    Layout.fillHeight: false
    implicitWidth: Appearance.sizes.calendarDaySize
    implicitHeight: Appearance.sizes.calendarDaySize
    leftPadding: 0
    rightPadding: 0

    variant: "text"
    shape: "square"
    toggleable: true
    selected: isToday === 1
    enabled: isToday !== -1
    text: day
}
