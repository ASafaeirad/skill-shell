pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.m3 as M3
import QtQuick
import QtQuick.Layouts
import Quickshell

// One row of a tray item's menu: a separator or a menu item.
Loader {
    id: root
    required property QsMenuEntry menuEntry
    property bool forceIconColumn: false
    property bool forceSpecialInteractionColumn: false

    signal dismiss()
    signal openSubmenu(handle: QsMenuHandle)

    Layout.fillWidth: true
    Layout.topMargin: menuEntry.isSeparator ? Appearance.spacing.xxs * 2 : 0
    Layout.bottomMargin: menuEntry.isSeparator ? Appearance.spacing.xxs * 2 : 0

    sourceComponent: menuEntry.isSeparator ? separatorComponent : menuItemComponent

    Component {
        id: separatorComponent
        M3.Divider {}
    }

    Component {
        id: menuItemComponent

        M3.MenuItem {
            density: -3
            text: root.menuEntry.text
            leadingIconSource: root.menuEntry.icon
            reserveLeadingIcon: root.forceIconColumn
            reserveSelectionControl: root.forceSpecialInteractionColumn
            selectionControl: root.menuEntry.buttonType === QsMenuButtonType.RadioButton ? "radio"
                : root.menuEntry.buttonType === QsMenuButtonType.CheckBox ? "checkbox"
                : "none"
            checkState: root.menuEntry.checkState
            trailingIcon: root.menuEntry.hasChildren ? "chevron_right" : ""

            releaseAction: () => {
                if (root.menuEntry.hasChildren) {
                    root.openSubmenu(root.menuEntry);
                    return;
                }
                root.menuEntry.triggered();
                root.dismiss();
            }
            altAction: event => {
                // Not hog right-click
                event.accepted = false;
            }
        }
    }
}
