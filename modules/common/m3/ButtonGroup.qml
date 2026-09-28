import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

/**
 * Material 3 connected or segmented button group.
 * https://m3.material.io/components/button-groups
 *
 * M3.ButtonGroup { variant: "segmented"; options: [{ displayName: "On", value: true }]; currentValue: enabled }
 * variant: "connected" (default) | "segmented". Connected groups accept button children.
 * Segmented groups bind currentValue and emit selected(value); configKey can bind a setting.
 */
Rectangle {
    id: root

    default property alias groupData: connectedRow.data
    property string variant: "connected"
    property real padding: 0
    property alias spacing: connectedRow.spacing
    property alias uniformCellSizes: connectedRow.uniformCellSizes
    property alias clickIndex: connectedRow.clickIndex
    property alias childrenCount: connectedRow.childrenCount
    property string configKey: ""
    property list<var> options: []
    property var currentValue: null
    property bool readOnly: false
    property bool equalWidth: false
    property bool surface: false
    property bool compact: false

    signal selected(var value)

    readonly property real contentWidth: connectedRow.implicitWidth
    readonly property real segmentContentWidth: {
        let total = 0;
        for (let i = 0; i < segmentedRepeater.count; ++i) {
            const button = segmentedRepeater.itemAt(i);
            if (button)
                total += button.implicitWidth;
        }
        return total + Math.max(0, segmentedRepeater.count - 1) * segmentedFlow.spacing;
    }
    implicitWidth: variant === "segmented" ? segmentContentWidth + padding * 2 : connectedRow.implicitWidth + padding * 2
    implicitHeight: variant === "segmented" ? segmentedFlow.childrenRect.height + padding * 2 : connectedRow.implicitHeight + padding * 2
    color: variant === "connected" || surface ? Appearance.colors.colLayer1 : "transparent"
    radius: Appearance.rounding.small
    Layout.fillWidth: variant === "segmented"

    Binding {
        target: root
        property: "currentValue"
        value: Config.getNestedValue(root.configKey)
        when: root.configKey !== ""
        restoreMode: Binding.RestoreBindingOrValue
    }

    onSelected: value => {
        if (configKey && Config.getNestedValue(configKey) !== value)
            Config.setNestedValue(configKey, value);
    }

    RowLayout {
        id: connectedRow
        anchors.fill: parent
        anchors.margins: root.padding
        visible: root.variant === "connected"
        spacing: Appearance.spacing.xs
        property int clickIndex: -1
        readonly property int childrenCount: children.length
    }

    Flow {
        id: segmentedFlow
        x: root.padding
        y: root.padding
        width: root.width - root.padding * 2
        visible: root.variant === "segmented"
        spacing: Appearance.sizes.m3OutlineWidth
        Repeater {
            id: segmentedRepeater
            model: root.variant === "segmented" ? root.options : []
            delegate: Button {
                required property var modelData
                required property int index
                variant: "outlined"
                toggleable: true
                selectedVariant: "filled"
                selected: root.currentValue == modelData.value
                text: modelData.displayName ?? ""
                materialIcon: modelData.icon ?? ""
                implicitHeight: root.compact ? Appearance.sizes.m3ChipHeightCompact : Appearance.sizes.m3ButtonHeight
                width: root.equalWidth ? (segmentedFlow.width - (root.options.length - 1) * segmentedFlow.spacing) / root.options.length : implicitWidth
                buttonRadius: 0
                buttonLeftRadius: index === 0 ? Appearance.rounding.full : 0
                buttonRightRadius: index === root.options.length - 1 ? Appearance.rounding.full : 0
                pointingHandCursor: !root.readOnly
                rippleEnabled: !root.readOnly
                onClicked: if (!root.readOnly) root.selected(modelData.value)
            }
        }
    }
}
