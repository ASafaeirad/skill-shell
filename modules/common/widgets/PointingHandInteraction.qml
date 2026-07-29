import QtQuick

MouseArea {
    anchors.fill: parent
    onPressed: (mouse) => {
        return mouse.accepted = false;
    }
    cursorShape: Qt.PointingHandCursor
}
