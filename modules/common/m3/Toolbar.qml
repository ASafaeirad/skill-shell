import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

/**
 * Material 3 toolbar: a row of actions for the current page or selection.
 * https://m3.material.io/components/toolbars
 *
 *   M3.Toolbar {
 *       M3.IconButton { materialIcon: "shuffle"; tooltip: "Random" }
 *       M3.ToolbarTextField { placeholderText: "Search" }
 *   }
 *
 * variant: "floating" (default, a pill that floats over content, elevated) |
 *   "docked" (full width, square, flat; fill the width with Layout or anchors)
 * elevated: draws the shadow; on by default for the floating toolbar.
 * Children are laid out in a row. Use M3.IconButton with
 * `toggleable: true; selectedVariant: "tonal"` for toggles, M3.ToolbarTextField
 * for an input, and put a paired M3.Fab { size: "toolbar"; variant: "tertiary" }
 * beside the toolbar, not inside it.
 */
Item {
    id: root

    property string variant: "floating"
    readonly property bool floating: variant !== "docked"
    property bool elevated: floating
    property real padding: Appearance.spacing.s
    property alias spacing: toolbarLayout.spacing
    default property alias toolbarData: toolbarLayout.data

    implicitWidth: toolbarLayout.implicitWidth + padding * 2
    implicitHeight: floating ? Appearance.sizes.m3ToolbarFloatingHeight : Appearance.sizes.m3ToolbarDockedHeight

    StyledRectangularShadow {
        visible: root.elevated
        target: background
    }

    Rectangle {
        id: background

        anchors.fill: parent
        color: Appearance.m3colors.m3surfaceContainer
        radius: root.floating ? height / 2 : 0
    }

    RowLayout {
        id: toolbarLayout

        spacing: Appearance.spacing.xxs * 2

        anchors {
            fill: parent
            margins: root.padding
        }
    }
}
