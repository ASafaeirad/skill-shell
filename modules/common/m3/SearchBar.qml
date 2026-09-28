import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

/**
 * Material 3 search bar: the pill-shaped query field that opens a search.
 * https://m3.material.io/components/search
 *
 *   M3.SearchBar { placeholderText: "Search apps"; onTextChanged: Search.query = text }
 *
 * It is the input only. A leading icon or trailing actions (M3.IconButton) sit
 * beside it in the caller's row, as the launcher does.
 * Builds on M3.ToolbarTextField.
 * compact: 40 px tall instead of 56, for a bar inside a toolbar or popup.
 */
ToolbarTextField {
    id: root

    property bool compact: false

    Layout.fillHeight: false
    implicitHeight: compact ? Appearance.sizes.m3SearchBarHeightCompact : Appearance.sizes.m3SearchBarHeight
    leftPadding: compact ? Appearance.spacing.m : Appearance.spacing.lg
    rightPadding: leftPadding
    topPadding: 0
    bottomPadding: 0
    verticalAlignment: TextInput.AlignVCenter
    font.pixelSize: compact ? Appearance.font.pixelSize.small : Appearance.font.pixelSize.normal
}
