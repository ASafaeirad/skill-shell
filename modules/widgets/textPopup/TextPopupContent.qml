import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.modules.common
import qs.modules.common.widgets

/**
 * The popup dialog itself: an OverlayDialogCard (surface + transition shared
 * with the selector and pinentry) with read-only, scrollable body text.
 */
OverlayDialogCard {
    id: root

    property string title: ""
    property string body: ""
    property int maxBodyHeight: 500

    signal dismissed()

    function copyBody() {
        Quickshell.execDetached(["wl-copy", "--", root.body]);
    }

    Component.onCompleted: animateIn()
    implicitWidth: 600
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
        spacing: 16

        WindowDialogTitle {
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

            WindowDialogParagraph {
                id: bodyText

                width: bodyFlickable.width
                text: root.body
            }
        }

        WindowDialogButtonRow {
            Item {
                Layout.fillWidth: true
            }

            DialogButton {
                buttonText: "Copy"
                onClicked: root.copyBody()
            }

            DialogButton {
                buttonText: "Close"
                onClicked: root.dismissed()
            }
        }
    }

    // Keep the surface and the scrolling body resizing in lockstep.
    Behavior on implicitHeight {
        animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
    }
}
