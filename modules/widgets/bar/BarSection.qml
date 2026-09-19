import QtQuick
import QtQuick.Layouts
import qs.modules.widgets.bar as Bar

Repeater {
    id: root

    property string section: "end"
    property bool vertical: false
    property real useShortenedForm: 0
    property bool areaHovered: false

    model: Bar.BarRoster.widgetsForSection(root.section)

    delegate: Loader {
        id: delegateLoader

        required property var modelData

        active: Bar.BarRoster.isWidgetVisible(modelData, root.vertical, root.useShortenedForm)
        visible: active

        sourceComponent: root.vertical
            ? (modelData.verticalComponent ?? modelData.component)
            : (modelData.horizontalComponent ?? modelData.component)

        Layout.fillWidth: item ? (item.Layout.fillWidth ?? false) : false
        Layout.fillHeight: item ? (item.Layout.fillHeight ?? false) : false
        Layout.alignment: item ? (item.Layout.alignment ?? (root.vertical ? Qt.AlignHCenter : Qt.AlignVCenter))
                               : (root.vertical ? Qt.AlignHCenter : Qt.AlignVCenter)
        Layout.preferredWidth: (item && item.Layout.preferredWidth > 0) ? item.Layout.preferredWidth : -1
        Layout.preferredHeight: (item && item.Layout.preferredHeight > 0) ? item.Layout.preferredHeight : -1
        Layout.leftMargin: item ? item.Layout.leftMargin : 0
        Layout.rightMargin: item ? item.Layout.rightMargin : 0
        Layout.topMargin: item ? item.Layout.topMargin : 0
        Layout.bottomMargin: item ? item.Layout.bottomMargin : 0

        Binding {
            target: delegateLoader.item
            property: "parentHovered"
            value: root.areaHovered
            when: delegateLoader.item && delegateLoader.item.hasOwnProperty("parentHovered")
        }
    }
}
