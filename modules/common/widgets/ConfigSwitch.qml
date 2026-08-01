import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

RippleButton {
    id: root

    property string buttonIcon
    property alias iconSize: iconWidget.iconSize
    property string configKey: ""

    Layout.fillWidth: true
    implicitHeight: contentItem.implicitHeight + 8 * 2
    font.pixelSize: Appearance.font.pixelSize.small
    onClicked: checked = !checked
    onCheckedChanged: {
        if (configKey && Config.getNestedValue(configKey) !== checked)
            Config.setNestedValue(configKey, checked);
    }

    Binding {
        target: root
        property: "checked"
        value: Config.getNestedValue(root.configKey)
        when: root.configKey !== ""
        restoreMode: Binding.RestoreBindingOrValue
    }

    contentItem: RowLayout {
        spacing: 10

        OptionalMaterialSymbol {
            id: iconWidget

            icon: root.buttonIcon
            opacity: root.enabled ? 1 : 0.4
            iconSize: Appearance.font.pixelSize.larger
        }

        StyledText {
            id: labelWidget

            Layout.fillWidth: true
            text: root.text
            font: root.font
            color: Appearance.colors.colOnSecondaryContainer
            opacity: root.enabled ? 1 : 0.4
        }

        StyledSwitch {
            id: switchWidget

            down: root.down
            Layout.fillWidth: false
            checked: root.checked
            onClicked: root.clicked()
        }

    }

}
