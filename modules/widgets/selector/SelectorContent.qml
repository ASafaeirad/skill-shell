import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.services

OverlayDialogCard {
    id: root

    property var items: []
    property string prompt: "Select an item"
    // dmenu-style free-form input: when no entry matches, Enter returns the
    // typed text instead of doing nothing. Shift+Enter always returns the
    // typed text, even while an entry is highlighted.
    property bool allowCustom: false
    // Sizing
    property int itemHeight: 40
    property int itemSpacing: 2
    property int maxListHeight: 360
    property real listContentHeight: filtered.length * itemHeight + Math.max(0, filtered.length - 1) * itemSpacing
    property real visibleListHeight: Math.min(listContentHeight, maxListHeight)
    // Free-form affordance shown when nothing matches what's typed.
    property bool showCustomRow: allowCustom && filtered.length === 0 && query.trim().length > 0
    property string query: searchField.text
    property var filtered: {
        const q = query.trim().toLowerCase();
        const out = [];
        for (let i = 0; i < items.length; i++) {
            const label = displayText(items[i]).toLowerCase();
            if (q.length === 0 || label.includes(q))
                out.push({
                    "item": items[i],
                    "index": i
                });

        }
        return out;
    }

    signal selected(var item, int index)
    // Emitted when the user confirms free-form text that isn't a list entry.
    signal submitted(string text)
    signal cancelled()

    // Reset input each time the panel opens. Without this, reopening while
    // the previous exit animation is still playing reuses this same instance
    // with stale query text (e.g. running menu twice back-to-back).
    onAboutToAnimateIn: searchField.text = ""

    // --- Filtering ---------------------------------------------------------
    // Each filtered entry keeps the item and its original index so the
    // consumer always gets back the real source entry.
    function displayText(item) {
        return (typeof item === "object" && item !== null) ? (item.name ?? "") : String(item);
    }

    function iconOf(item) {
        return (typeof item === "object" && item !== null) ? (item.icon ?? "") : "";
    }

    function activateCurrent() {
        if (listView.currentIndex >= 0 && listView.currentIndex < filtered.length) {
            const entry = filtered[listView.currentIndex];
            root.selected(entry.item, entry.index);
            return ;
        }
        root.submitCustom();
    }

    // Confirm whatever is typed, ignoring the highlighted entry. No-op unless
    // the caller asked for free-form input and something was actually typed.
    function submitCustom() {
        if (!root.allowCustom)
            return ;

        const text = root.query.trim();
        if (text.length === 0)
            return ;

        root.submitted(text);
    }

    Component.onCompleted: {
        searchField.forceActiveFocus();
        animateIn();
    }
    implicitWidth: 500
    // Grow with the number of results, up to maxListHeight, then scroll.
    implicitHeight: 2 * Appearance.sizes.elevationMargin + 2 * 12 + searchField.implicitHeight + 8 + visibleListHeight + (showCustomRow ? itemHeight : 0)
    onFilteredChanged: listView.currentIndex = filtered.length > 0 ? 0 : -1

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8

        MaterialTextField {
            id: searchField

            Layout.fillWidth: true
            placeholderText: root.prompt
            focus: true
            Keys.onPressed: (event) => {
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
                    if (event.modifiers & Qt.ShiftModifier)
                        root.submitCustom();
                    else
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
                color: (index === listView.currentIndex) ? Appearance.colors.colPrimaryContainer : itemMouse.containsMouse ? Appearance.colors.colLayer1Hover : "transparent"

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

        Rectangle {
            id: customRow

            Layout.fillWidth: true
            Layout.preferredHeight: root.itemHeight
            visible: root.showCustomRow
            radius: Appearance.rounding.small
            color: customMouse.containsMouse ? Appearance.colors.colLayer1Hover : Appearance.colors.colPrimaryContainer

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 10

                MaterialSymbol {
                    text: "keyboard_return"
                    iconSize: Appearance.font.pixelSize.larger
                    color: Appearance.colors.colOnPrimaryContainer
                }

                StyledText {
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    text: `Use "${root.query.trim()}"`
                    color: Appearance.colors.colOnPrimaryContainer
                }

            }

            MouseArea {
                id: customMouse

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.submitCustom()
            }

        }

    }


    // Animate the list height itself (implicitHeight derives from it), so the
    // container and the ListView resize in lockstep and the list never pokes
    // out of the background mid-transition.
    Behavior on visibleListHeight {
        animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
    }

}
