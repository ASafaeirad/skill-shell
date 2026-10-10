import qs.modules.common
import QtQuick
import QtQuick.Controls.Material
import QtQuick.Controls.Material as MaterialControls

/**
 * Material 3 text field, single line.
 * https://m3.material.io/components/text-fields
 *
 *   M3.TextField { placeholderText: "Name"; text: root.name; onTextChanged: root.name = text }
 *
 * For multiline text use M3.TextArea.
 * Note: We don't use NativeRendering because it makes the small placeholder text look weird
 */
// Select Material explicitly: the shell's default Controls style is Basic.
MaterialControls.TextField {
    id: root
    Material.theme: Material.System
    Material.accent: Appearance.m3colors.m3primary
    Material.primary: Appearance.m3colors.m3primary
    Material.background: Appearance.m3colors.m3surface
    Material.foreground: Appearance.m3colors.m3onSurface
    Material.containerStyle: Material.Outlined
    renderType: Text.QtRendering

    selectedTextColor: Appearance.m3colors.m3onSecondaryContainer
    selectionColor: Appearance.colors.colSecondaryContainer
    placeholderTextColor: activeFocus ? Appearance.m3colors.m3primary : Appearance.m3colors.m3onSurfaceVariant
    clip: true

    font {
        family: Appearance.font.family.main
        pixelSize: Appearance.font.pixelSize.small
        hintingPreference: Font.PreferFullHinting
        variableAxes: Appearance.font.variableAxes.main
    }
    wrapMode: TextEdit.Wrap

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        hoverEnabled: true
        cursorShape: Qt.IBeamCursor
    }
}
