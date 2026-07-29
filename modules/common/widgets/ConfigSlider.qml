import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.services

RowLayout {
    id: root

    property string text: ""
    property string buttonIcon: ""
    property alias value: slider.value
    property alias stopIndicatorValues: slider.stopIndicatorValues
    property bool usePercentTooltip: true
    property real from: slider.from
    property real to: slider.to
    property real textWidth: 120

    spacing: 10
    Layout.leftMargin: 8
    Layout.rightMargin: 8

    RowLayout {
        id: row

        spacing: 10

        OptionalMaterialSymbol {
            id: iconWidget

            icon: root.buttonIcon
            iconSize: Appearance.font.pixelSize.larger
        }

        StyledText {
            id: labelWidget

            Layout.preferredWidth: root.textWidth
            text: root.text
            color: Appearance.colors.colOnSecondaryContainer
        }

    }

    StyledSlider {
        id: slider

        configuration: StyledSlider.Configuration.XS
        usePercentTooltip: root.usePercentTooltip
        value: root.value
        from: root.from
        to: root.to
    }

}
