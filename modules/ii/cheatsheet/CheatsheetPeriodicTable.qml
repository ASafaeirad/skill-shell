import QtQuick
import "periodic_table.js" as PTable

Item {
    id: root

    readonly property var elements: PTable.elements
    readonly property var series: PTable.series
    property real spacing: 6

    implicitWidth: mainLayout.implicitWidth
    implicitHeight: mainLayout.implicitHeight

    Column {
        id: mainLayout

        anchors.centerIn: parent
        spacing: root.spacing

        // Main table rows
        Repeater {
            model: root.elements

            // Table cells
            delegate: Row {
                id: tableRow

                required property var modelData

                spacing: root.spacing

                Repeater {
                    model: tableRow.modelData

                    delegate: ElementTile {
                        required property var modelData

                        element: modelData
                    }

                }

            }

        }

        Item {
            id: gap

            implicitHeight: 20
        }

        // Main table rows
        Repeater {
            model: root.series

            // Table cells
            delegate: Row {
                id: seriesTableRow

                required property var modelData

                spacing: root.spacing

                Repeater {
                    model: seriesTableRow.modelData

                    delegate: ElementTile {
                        required property var modelData

                        element: modelData
                    }

                }

            }

        }

    }

}
