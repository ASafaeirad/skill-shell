import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

// Navigation rail with one tab per model entry: { name, icon, iconRotation? }.
// Bind currentIndex and handle tabSelected to switch pages.
NavigationRail {
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
