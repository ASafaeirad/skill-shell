import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

TextField {
    id: filterField

    property alias colBackground: background.color

    Layout.fillHeight: true
    implicitWidth: 200
    padding: 10
    placeholderTextColor: Appearance.colors.colSubtext
    color: Appearance.colors.colOnLayer1
    renderType: Text.NativeRendering
    selectedTextColor: Appearance.colors.colOnSecondaryContainer
    selectionColor: Appearance.colors.colSecondaryContainer

    font {
        family: Appearance.font.family.main
        pixelSize: Appearance.font.pixelSize.small
        hintingPreference: Font.PreferFullHinting
        variableAxes: Appearance.font.variableAxes.main
    }

    background: Rectangle {
        id: background

        color: Appearance.colors.colLayer1
        radius: Appearance.rounding.full
    }

}
