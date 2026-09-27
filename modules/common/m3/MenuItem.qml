import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

/**
 * Material 3 menu item: one row of a menu.
 * https://m3.material.io/components/menus
 *
 *   M3.MenuItem { leadingIcon: "push_pin"; text: "Pin"; onClicked: ... }
 *   M3.MenuItem { text: "Show hidden"; selectionControl: "checkbox"; checkState: Qt.Checked }
 *   M3.MenuItem { text: "More"; trailingIcon: "chevron_right" }   // opens a submenu
 *
 * Separate groups with M3.Divider; a menu item is never a separator itself.
 *
 * density: 0 (48 px, default) down to -3 (36 px), the Material density scale, for
 *   the packed menus a desktop shell needs.
 * leadingIconSource: an image instead of a symbol, for menus fed by an application
 *   (a tray menu).
 * reserveSelectionControl / reserveLeadingIcon: keep the column even when this item
 *   has nothing in it, so the labels of a menu whose items differ still line up.
 */
RippleButton {
    id: root

    property real density: 0
    property string leadingIcon: ""
    property url leadingIconSource
    property bool reserveLeadingIcon: false
    property string selectionControl: "none" // "none" | "checkbox" | "radio"
    property int checkState: Qt.Unchecked
    property bool reserveSelectionControl: false
    property string trailingIcon: ""
    property string trailingText: ""

    readonly property color labelColor: enabled ? Appearance.colors.colOnSurface
        : ColorUtils.applyAlpha(Appearance.colors.colOnSurface, Appearance.stateLayer.disabledContent)
    readonly property color iconColor: enabled ? Appearance.colors.colOnSurfaceVariant
        : ColorUtils.applyAlpha(Appearance.colors.colOnSurface, Appearance.stateLayer.disabledContent)
    readonly property real columnSize: Appearance.font.pixelSize.larger

    implicitHeight: Appearance.sizes.m3MenuItemHeight + density * Appearance.sizes.m3DensityStep
    leftPadding: Appearance.spacing.m
    rightPadding: Appearance.spacing.m
    buttonRadius: Appearance.rounding.small
    opacity: 1

    colBackground: "transparent"
    colBackgroundHover: ColorUtils.stateLayer("transparent", Appearance.colors.colOnSurface, Appearance.stateLayer.hover)
    colRipple: ColorUtils.applyAlpha(Appearance.colors.colOnSurface, Appearance.stateLayer.pressed * 2)
    buttonColor: hovered ? colBackgroundHover : colBackground

    contentItem: RowLayout {
        spacing: Appearance.spacing.s

        // M3 shows a menu item's selection state in its leading column.
        Item {
            visible: root.selectionControl !== "none" || root.reserveSelectionControl
            implicitWidth: root.columnSize
            implicitHeight: root.columnSize

            MaterialSymbol {
                anchors.centerIn: parent
                visible: text.length > 0
                iconSize: root.columnSize
                color: root.iconColor
                text: root.selectionControl === "radio" ? (root.checkState === Qt.Checked ? "radio_button_checked" : "radio_button_unchecked")
                    : root.selectionControl !== "checkbox" ? ""
                    : root.checkState === Qt.Checked ? "check"
                    : root.checkState === Qt.PartiallyChecked ? "check_indeterminate_small"
                    : ""
            }
        }

        Item {
            visible: root.leadingIcon.length > 0 || root.leadingIconSource != "" || root.reserveLeadingIcon
            implicitWidth: root.columnSize
            implicitHeight: root.columnSize

            MaterialSymbol {
                anchors.centerIn: parent
                visible: root.leadingIcon.length > 0
                text: root.leadingIcon
                iconSize: root.columnSize
                color: root.iconColor
            }
            IconImage {
                anchors.centerIn: parent
                visible: root.leadingIconSource != ""
                asynchronous: true
                source: root.leadingIconSource
                implicitSize: root.columnSize
                mipmap: true
            }
        }

        StyledText {
            Layout.fillWidth: true
            text: root.text
            color: root.labelColor
            font.pixelSize: Appearance.font.pixelSize.smallie
            elide: Text.ElideRight
        }

        StyledText {
            visible: root.trailingText.length > 0
            text: root.trailingText
            color: root.iconColor
            font.pixelSize: Appearance.font.pixelSize.smaller
        }

        MaterialSymbol {
            visible: root.trailingIcon.length > 0
            text: root.trailingIcon
            iconSize: root.columnSize
            color: root.iconColor
        }
    }
}
