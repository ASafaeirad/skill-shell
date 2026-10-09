import QtQuick
import QtQuick.Layouts
import qs.modules.common.m3 as M3

M3.IconButton {
    id: button

    variant: button.activeFocus ? "filled" : "tonal"
    size: "xlarge"
    shape: "square"
    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            button.down = true;
            button.clicked();
            event.accepted = true;
        }
    }
    Keys.onReleased: event => {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            button.down = false;
            event.accepted = true;
        }
    }
}
