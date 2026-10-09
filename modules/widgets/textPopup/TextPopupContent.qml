import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.m3 as M3

/**
 * The popup dialog itself: an M3.DialogCard (surface + transition shared
 * with the selector and pinentry) with read-only, scrollable body text.
 */
M3.DialogCard {
    id: root

    property string title: ""
    property string body: ""
    property int maxBodyHeight: Appearance.sizes.textPopupMaxBodyHeight

    signal dismissed()

    function copyBody() {
        Quickshell.execDetached(["wl-copy", "--", root.body]);
    }

    Component.onCompleted: animateIn()
    implicitWidth: Appearance.sizes.textPopupWidth
    implicitHeight: 2 * Appearance.sizes.elevationMargin + 2 * padding + contentColumn.implicitHeight

    // Show new text from the top.
    onBodyChanged: bodyFlickable.contentY = 0

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            root.dismissed();
            event.accepted = true;
        } else if (event.key === Qt.Key_C && (event.modifiers & Qt.ControlModifier)) {
            root.copyBody();
            event.accepted = true;
        } else {
            event.accepted = false;
        }
    }

    ColumnLayout {
        id: contentColumn

        anchors.fill: parent
        anchors.margins: root.padding
        spacing: Appearance.spacing.lg

        M3.DialogTitle {
            Layout.fillWidth: true
            visible: root.title.length > 0
            text: root.title
        }

        StyledFlickable {
            id: bodyFlickable

            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(bodyText.implicitHeight, root.maxBodyHeight)
            contentWidth: width
            contentHeight: bodyText.implicitHeight
            clip: true

            M3.DialogParagraph {
                id: bodyText

                width: bodyFlickable.width
                text: root.body
            }
        }

        M3.DialogButtonRow {
            Item {
                Layout.fillWidth: true
            }

            M3.Button {
                variant: "text"
                text: "Copy"
                onClicked: root.copyBody()
            }

            M3.Button {
                variant: "text"
                text: "Close"
                onClicked: root.dismissed()
            }
        }
    }

    // Keep the surface and the scrolling body resizing in lockstep.
    Behavior on implicitHeight {
        animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
    }
}
