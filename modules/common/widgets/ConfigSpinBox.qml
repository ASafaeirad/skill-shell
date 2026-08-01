import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

RowLayout {
    id: root

    property string text: ""
    property string icon
    property string configKey: ""
    property alias value: spinBoxWidget.value
    property alias stepSize: spinBoxWidget.stepSize
    property alias from: spinBoxWidget.from
    property alias to: spinBoxWidget.to

    spacing: 10
    Layout.leftMargin: 8
    Layout.rightMargin: 8

    RowLayout {
        spacing: 10

        OptionalMaterialSymbol {
            icon: root.icon
            opacity: root.enabled ? 1 : 0.4
        }

        StyledText {
            id: labelWidget

            Layout.fillWidth: true
            text: root.text
            color: Appearance.colors.colOnSecondaryContainer
            opacity: root.enabled ? 1 : 0.4
        }

    }

    StyledSpinBox {
        id: spinBoxWidget

        Layout.fillWidth: false
        onValueChanged: {
            if (root.configKey && Config.getNestedValue(root.configKey) !== value)
                Config.setNestedValue(root.configKey, value);
        }
    }

    Binding {
        target: spinBoxWidget
        property: "value"
        value: Config.getNestedValue(root.configKey)
        when: root.configKey !== ""
        restoreMode: Binding.RestoreBindingOrValue
    }

}
