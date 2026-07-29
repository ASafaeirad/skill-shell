import QtQuick
import QtQuick.Controls
import qs.modules.common
import qs.modules.common.widgets

ListView {
    id: root

    boundsBehavior: Flickable.DragOverBounds

    ScrollBar.vertical: WScrollBar {
    }

    displaced: Transition {
        animations: [Looks.transition.enter.createObject(this, {
            "property": "y"
        })]
    }

}
