import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

Rectangle {
    id: root
    property string title: ""
    property string description: ""
    default property alias previewData: preview.data

    Layout.fillWidth: true
    implicitHeight: content.implicitHeight + Appearance.spacing.xl * 2
    radius: Appearance.rounding.normal
    color: Appearance.m3colors.m3surfaceContainer
    border.width: 1
    border.color: Appearance.m3colors.m3outlineVariant

    ColumnLayout {
        id: content
        anchors.fill: parent
        anchors.margins: Appearance.spacing.xl
        spacing: Appearance.spacing.m

        StyledText {
            text: root.title
            color: Appearance.m3colors.m3onSurface
            font.pixelSize: Appearance.font.pixelSize.larger
        }

        StyledText {
            visible: root.description.length > 0
            text: root.description
            color: Appearance.m3colors.m3onSurfaceVariant
            font.pixelSize: Appearance.font.pixelSize.smallie
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        Flow {
            id: preview
            Layout.fillWidth: true
            spacing: Appearance.spacing.m
        }
    }
}
