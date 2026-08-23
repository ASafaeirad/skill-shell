import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.modules.common
import qs.modules.common.widgets

/**
 * The popup dialog itself: dialog surface and typography shared with the
 * WindowDialog family, enter/exit transition shared with the selector.
 */
Item {
    id: root

    property string title: ""
    property string body: ""
    property int maxBodyHeight: 500

    // Matches WindowDialog, which pads its content by the surface radius.
    readonly property real padding: Appearance.rounding.large

    // --- Enter / exit slide-and-fade transition, as in SelectorContent -----
    property real slideDistance: 40
    property real yOffset: slideDistance

    signal dismissed()
    // Emitted once the slide-down finishes, so the panel can unload.
    signal closeFinished()

    function animateIn() {
        exitAnim.stop();
        enterAnim.start();
    }

    function animateOut() {
        enterAnim.stop();
        exitAnim.start();
    }

    function copyBody() {
        Quickshell.execDetached(["wl-copy", "--", root.body]);
    }

    opacity: 0
    Component.onCompleted: animateIn()
    implicitWidth: 600
    implicitHeight: 2 * Appearance.sizes.elevationMargin + 2 * padding + contentColumn.implicitHeight

    // Show new text from the top.
    onBodyChanged: bodyFlickable.contentY = 0

    ParallelAnimation {
        id: enterAnim

        NumberAnimation {
            target: root
            property: "yOffset"
            to: 0
            duration: Appearance.animation.elementMoveEnter.duration
            easing.type: Appearance.animation.elementMoveEnter.type
            easing.bezierCurve: Appearance.animation.elementMoveEnter.bezierCurve
        }

        NumberAnimation {
            target: root
            property: "opacity"
            to: 1
            duration: Appearance.animation.elementMoveEnter.duration
            easing.type: Appearance.animation.elementMoveEnter.type
            easing.bezierCurve: Appearance.animation.elementMoveEnter.bezierCurve
        }
    }

    ParallelAnimation {
        id: exitAnim

        onFinished: root.closeFinished()

        NumberAnimation {
            target: root
            property: "yOffset"
            to: root.slideDistance
            duration: Appearance.animation.elementMoveExit.duration
            easing.type: Appearance.animation.elementMoveExit.type
            easing.bezierCurve: Appearance.animation.elementMoveExit.bezierCurve
        }

        NumberAnimation {
            target: root
            property: "opacity"
            to: 0
            duration: Appearance.animation.elementMoveExit.duration
            easing.type: Appearance.animation.elementMoveExit.type
            easing.bezierCurve: Appearance.animation.elementMoveExit.bezierCurve
        }
    }

    Rectangle {
        id: background

        anchors.fill: parent
        anchors.margins: Appearance.sizes.elevationMargin
        color: Appearance.m3colors.m3surfaceContainerHigh // Same dialog surface as WindowDialog
        radius: Appearance.rounding.large

        // Clicks inside the dialog shouldn't reach the dismissing scrim.
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            hoverEnabled: true
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
    }

    transform: Translate {
        y: root.yOffset
    }

    // Keep the surface and the scrolling body resizing in lockstep.
    Behavior on implicitHeight {
        animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
    }
}
