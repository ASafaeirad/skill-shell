import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

ColumnLayout {
    id: root

    property string title
    property string icon: ""
    // Optional right-hand side of the title row, for a status chip that belongs to the
    // section as a whole rather than to any one control inside it.
    property Component headerTrailing: null
    default property alias contentData: sectionContent.data

    Layout.fillWidth: true
    spacing: 6

    RowLayout {
        Layout.fillWidth: true
        spacing: 6

        OptionalMaterialSymbol {
            icon: root.icon
            iconSize: Appearance.font.pixelSize.hugeass
        }

        StyledText {
            text: root.title
            font.pixelSize: Appearance.font.pixelSize.larger
            font.weight: Font.Medium
            color: Appearance.colors.colOnSecondaryContainer
        }

        Item {
            Layout.fillWidth: true
        }

        // The slot sits after the spacer, so a trailing item that hides itself costs the row
        // nothing: the width it keeps is width the spacer would have eaten anyway.
        Loader {
            active: root.headerTrailing !== null
            visible: active
            sourceComponent: root.headerTrailing
        }
    }

    ColumnLayout {
        id: sectionContent

        Layout.fillWidth: true
        spacing: 4
    }

}
