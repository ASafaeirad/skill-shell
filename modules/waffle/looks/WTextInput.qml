import QtQuick
import QtQuick.Controls

TextInput {
    id: root

    renderType: Text.NativeRendering
    verticalAlignment: Text.AlignVCenter
    color: Looks.colors.fg
    selectionColor: Looks.colors.selection
    selectedTextColor: Looks.colors.selectionFg

    font {
        hintingPreference: Font.PreferFullHinting
        family: Looks.font.family.ui
        pixelSize: Looks.font.pixelSize.large
        weight: Looks.font.weight.regular
    }

}
