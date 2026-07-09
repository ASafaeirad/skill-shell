import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

Item {
    id: root

    property var items: []
    property string prompt: Translation.tr("Select an item")

    signal selected(var item, int index)
    signal cancelled
    // Emitted once the slide-down finishes, so the panel can unload.
    signal closeFinished

    // --- Enter / exit slide-and-fade transition ----------------------------
    property real slideDistance: 40
    property real yOffset: slideDistance
    opacity: 0
    transform: Translate { y: root.yOffset }

    function animateIn() {
        // Reset input each time the panel opens. Without this, reopening while
        // the previous exit animation is still playing reuses this same instance
        // with stale query text (e.g. running ii-menu twice back-to-back).
        searchField.text = "";
        exitAnim.stop();
        enterAnim.start();
    }
    function animateOut() {
        enterAnim.stop();
        exitAnim.start();
    }
    Component.onCompleted: {
        searchField.forceActiveFocus();
        animateIn();
    }

    ParallelAnimation {
        id: enterAnim
        NumberAnimation {
            target: root; property: "yOffset"; to: 0
            duration: Appearance.animation.elementMoveEnter.duration
            easing.type: Appearance.animation.elementMoveEnter.type
            easing.bezierCurve: Appearance.animation.elementMoveEnter.bezierCurve
        }
        NumberAnimation {
            target: root; property: "opacity"; to: 1
            duration: Appearance.animation.elementMoveEnter.duration
            easing.type: Appearance.animation.elementMoveEnter.type
            easing.bezierCurve: Appearance.animation.elementMoveEnter.bezierCurve
        }
    }
    ParallelAnimation {
        id: exitAnim
        onFinished: root.closeFinished()
        NumberAnimation {
            target: root; property: "yOffset"; to: root.slideDistance
            duration: Appearance.animation.elementMoveExit.duration
            easing.type: Appearance.animation.elementMoveExit.type
            easing.bezierCurve: Appearance.animation.elementMoveExit.bezierCurve
        }
        NumberAnimation {
            target: root; property: "opacity"; to: 0
            duration: Appearance.animation.elementMoveExit.duration
            easing.type: Appearance.animation.elementMoveExit.type
            easing.bezierCurve: Appearance.animation.elementMoveExit.bezierCurve
        }
    }

    // Sizing
    property int itemHeight: 40
    property int itemSpacing: 2
    property int maxListHeight: 360
    property real listContentHeight: filtered.length * itemHeight + Math.max(0, filtered.length - 1) * itemSpacing
    property real visibleListHeight: Math.min(listContentHeight, maxListHeight)

    implicitWidth: 500
    // Grow with the number of results, up to maxListHeight, then scroll.
    implicitHeight: 2 * Appearance.sizes.elevationMargin + 2 * 12 + searchField.implicitHeight + 8 + visibleListHeight

    Behavior on implicitHeight {
        animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
    }

    // --- Filtering ---------------------------------------------------------
    // Each filtered entry keeps the item and its original index so the
    // consumer always gets back the real source entry.
    function displayText(item) {
        return (typeof item === "object" && item !== null) ? (item.name ?? "") : String(item);
    }
    function iconOf(item) {
        return (typeof item === "object" && item !== null) ? (item.icon ?? "") : "";
    }

    property string query: searchField.text
    property var filtered: {
        const q = query.trim().toLowerCase();
        const out = [];
        for (let i = 0; i < items.length; i++) {
            const label = displayText(items[i]).toLowerCase();
            if (q.length === 0 || label.includes(q)) {
                out.push({ item: items[i], index: i });
            }
        }
        return out;
    }
    onFilteredChanged: listView.currentIndex = filtered.length > 0 ? 0 : -1

    function activateCurrent() {
        if (listView.currentIndex < 0 || listView.currentIndex >= filtered.length)
            return;
        const entry = filtered[listView.currentIndex];
        root.selected(entry.item, entry.index);
    }

    Rectangle {
        id: background
        anchors.fill: parent
        anchors.margins: Appearance.sizes.elevationMargin
        color: Appearance.m3colors.m3surfaceContainerHigh // Match Pinentry dialog surface
        radius: Appearance.rounding.large

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            MaterialTextField {
                id: searchField
                Layout.fillWidth: true
                placeholderText: root.prompt
                focus: true

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape) {
                        root.cancelled();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Down) {
                        if (root.filtered.length > 0)
                            listView.currentIndex = Math.min(listView.currentIndex + 1, root.filtered.length - 1);
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Up) {
                        if (root.filtered.length > 0)
                            listView.currentIndex = Math.max(listView.currentIndex - 1, 0);
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        root.activateCurrent();
                        event.accepted = true;
                    } else {
                        event.accepted = false;
                    }
                }
            }

            StyledListView {
                id: listView
                Layout.fillWidth: true
                Layout.preferredHeight: root.visibleListHeight
                visible: root.filtered.length > 0
                clip: true
                spacing: root.itemSpacing
                model: root.filtered
                currentIndex: 0

                delegate: Rectangle {
                    id: item
                    required property var modelData
                    required property int index
                    width: listView.width
                    height: root.itemHeight
                    radius: Appearance.rounding.small
                    color: (index === listView.currentIndex) ? Appearance.colors.colPrimaryContainer
                        : itemMouse.containsMouse ? Appearance.colors.colLayer1Hover
                        : "transparent"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 10

                        MaterialSymbol {
                            visible: text.length > 0
                            text: root.iconOf(item.modelData.item)
                            iconSize: Appearance.font.pixelSize.larger
                            color: (item.index === listView.currentIndex) ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colOnLayer0
                        }
                        StyledText {
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            text: root.displayText(item.modelData.item)
                            color: (item.index === listView.currentIndex) ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colOnLayer0
                        }
                    }

                    MouseArea {
                        id: itemMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: listView.currentIndex = item.index
                        onClicked: {
                            listView.currentIndex = item.index;
                            root.activateCurrent();
                        }
                    }
                }
            }
        }
    }
}
