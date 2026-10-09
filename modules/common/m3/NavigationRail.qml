import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.widgets as W

/**
 * Material 3 navigation rail, one tab per model entry: { name, icon, iconRotation? }.
 * https://m3.material.io/components/navigation-rail
 *
 *   M3.NavigationRail { model: root.pages; currentIndex: root.page; onTabSelected: index => root.page = index }
 *
 * Bind currentIndex and handle tabSelected to switch pages. expanded shows the labels
 * beside the icons.
 */
// NavigationRail alone would name this file; the rail container lives in widgets.
W.NavigationRail {
    id: root

    property var model: []
    signal tabSelected(int index)

    function tabAt(index) {
        return tabsRepeater.itemAt(index);
    }

    spacing: 10
    expanded: false

    NavigationRailTabArray {
        currentIndex: root.currentIndex
        expanded: root.expanded
        Repeater {
            id: tabsRepeater
            model: root.model
            NavigationRailButton {
                required property int index
                required property var modelData
                toggled: root.currentIndex === index
                onPressed: root.tabSelected(index)
                expanded: root.expanded
                buttonIcon: modelData.icon
                buttonIconRotation: modelData.iconRotation || 0
                buttonText: modelData.name
                showToggledHighlight: false
            }
        }
    }
}
