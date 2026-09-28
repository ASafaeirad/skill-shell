import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

/**
 * Material 3 toolbar text field: the pill-shaped input that sits in an M3.Toolbar.
 * https://m3.material.io/components/toolbars
 *
 *   M3.Toolbar { M3.ToolbarTextField { placeholderText: "Set FPS limit"; onAccepted: ... } }
 *
 * It fills the toolbar's height. For a search query use M3.SearchBar, which
 * builds on it.
 * drawsOwnText: hides the typed text and its selection so the caller can draw
 *   them itself, as the lock screen draws its password characters.
 */
TextField {
    id: root

    property bool drawsOwnText: false

    Layout.fillHeight: true
    implicitWidth: Appearance.sizes.m3ToolbarTextFieldWidth
    implicitHeight: Appearance.sizes.m3IconButtonSize
    padding: Appearance.spacing.m - Appearance.spacing.xxs
    color: drawsOwnText ? "transparent" : Appearance.colors.colOnSurface
    placeholderTextColor: Appearance.colors.colOnSurfaceVariant
    renderType: Text.NativeRendering
    selectedTextColor: drawsOwnText ? "transparent" : Appearance.colors.colOnSecondaryContainer
    selectionColor: drawsOwnText ? "transparent" : Appearance.colors.colSecondaryContainer

    font {
        family: Appearance.font.family.main
        pixelSize: Appearance.font.pixelSize.small
        hintingPreference: Font.PreferFullHinting
        variableAxes: Appearance.font.variableAxes.main
    }

    background: Rectangle {
        color: Appearance.colors.colSurfaceContainerHigh
        radius: Appearance.rounding.full
    }
}
