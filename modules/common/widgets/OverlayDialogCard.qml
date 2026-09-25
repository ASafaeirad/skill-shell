import QtQuick
import qs.modules.common

/**
 * The dialog card shared by the script-driven overlay dialogs (selector,
 * pinentry, text popup): a rounded surface that respects the transparency
 * config, plus the slide-and-fade enter/exit transition they all use.
 *
 * Callers set implicitWidth/implicitHeight and put their content inside; the
 * card reserves `Appearance.sizes.elevationMargin` around the visible surface.
 * Drive it with animateIn()/animateOut() and unload on closeFinished().
 */
Item {
    id: root

    default property alias cardData: background.data

    property real slideDistance: 40
    property real yOffset: slideDistance
    // Matches WindowDialog, which pads its content by the surface radius.
    property real padding: Appearance.spacing.xl
    property color surfaceColor: Appearance.colors.colBackgroundSurfaceContainerHigh
    // The visible surface, for callers that restyle its radius or border.
    readonly property alias surface: background

    // Emitted at the start of animateIn(), for resetting stale input before
    // the dialog slides back in (reopening mid-exit reuses the same instance).
    signal aboutToAnimateIn()
    // Emitted once the slide-down finishes, so the panel can unload.
    signal closeFinished()

    function animateIn(): void {
        root.aboutToAnimateIn();
        exitAnim.stop();
        enterAnim.start();
    }

    function animateOut(): void {
        enterAnim.stop();
        exitAnim.start();
    }

    opacity: 0

    transform: Translate {
        y: root.yOffset
    }

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
        color: root.surfaceColor
        radius: Appearance.rounding.large

        // Clicks inside the dialog shouldn't reach the dismissing scrim behind.
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            hoverEnabled: true
        }
    }
}
