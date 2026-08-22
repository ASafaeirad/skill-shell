pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

PanelWindow {
    id: root

    // Interface
    signal dismiss

    readonly property real minScale: 1
    readonly property real maxScale: 12
    readonly property real zoomStep: 1.15
    readonly property real ringStep: 1.35

    property real contentScale: 1
    property real contentX: 0
    property real contentY: 0
    property bool panning: false

    property real cursorX: width / 2
    property real cursorY: height / 2
    property real spotlightRadius: 90
    property bool dimEnabled: true

    // Intro: the ring starts wide and collapses onto the pointer so the eye can follow it there
    property real introProgress: 1
    readonly property real introRadius: Math.max(width, height) * 0.55
    readonly property real displayRadius: spotlightRadius + introProgress * (introRadius - spotlightRadius)

    readonly property real minSpotlightRadius: 30
    readonly property real maxSpotlightRadius: Math.min(width, height) / 2

    // SmoothedAnimation, not the shared elementMoveFast component: that one is `alwaysRunToEnd`,
    // so a burst of wheel events queues up full-length runs instead of tracking the pointer.
    Behavior on spotlightRadius {
        SmoothedAnimation {
            velocity: Appearance.animation.elementMoveFast.velocity
            easing.type: Easing.InOutQuad
        }
    }

    NumberAnimation on introProgress {
        running: screencopy.hasContent // Our own overlay must not end up inside the frozen frame
        from: 1
        to: 0
        duration: Appearance.animation.elementMoveEnter.duration
        easing.type: Appearance.animation.elementMoveEnter.type
        easing.bezierCurve: Appearance.animation.elementMoveEnter.bezierCurve
    }

    // Window props
    color: screencopy.hasContent ? "black" : "transparent" // Don't flash black while the pointer is being hidden
    WlrLayershell.namespace: "quickshell:screenZoom"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    exclusionMode: ExclusionMode.Ignore
    anchors {
        left: true
        right: true
        top: true
        bottom: true
    }

    // Keep the frozen frame covering the whole screen at all times
    function clampOffsets() {
        root.contentX = Math.min(0, Math.max(root.width - root.width * root.contentScale, root.contentX));
        root.contentY = Math.min(0, Math.max(root.height - root.height * root.contentScale, root.contentY));
    }

    // Zoom while keeping the point under (px, py) in place
    function zoomAt(px, py, factor) {
        const oldScale = root.contentScale;
        const newScale = Math.min(root.maxScale, Math.max(root.minScale, oldScale * factor));
        if (newScale === oldScale)
            return;
        const localX = (px - root.contentX) / oldScale;
        const localY = (py - root.contentY) / oldScale;
        root.contentScale = newScale;
        root.contentX = px - localX * newScale;
        root.contentY = py - localY * newScale;
        root.clampOffsets();
    }

    function reset() {
        root.contentScale = 1;
        root.contentX = 0;
        root.contentY = 0;
    }

    // Hyprland knows where the pointer is before it ever moves over us
    Process {
        running: true
        command: ["hyprctl", "cursorpos"]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split(",");
                if (parts.length !== 2)
                    return;
                const x = parseInt(parts[0]);
                const y = parseInt(parts[1]);
                if (isNaN(x) || isNaN(y))
                    return;
                root.cursorX = x - root.screen.x;
                root.cursorY = y - root.screen.y;
            }
        }
    }

    // Hyprland draws the pointer into the captured frame when it uses software cursors, so
    // `paintCursor: false` isn't enough — hide the pointer compositor-side, grab the frame,
    // then bring it back to sit on top of the freeze.
    property bool captureArmed: false

    // Clearing `invisible` only shows up on the next cursor update. Triggered from the mouse
    // there is always one, but triggered from a keybind nothing moves the pointer, so the
    // cursor stays gone until the user jiggles the mouse — warp it onto itself to force a redraw.
    readonly property string cursorUnhideLua: "hl.config({ cursor = { invisible = false } }) " + "local p = hl.get_cursor_pos() " + "hl.dispatch(hl.dsp.cursor.move({ x = p.x, y = p.y }))"

    function setCursorHidden(hidden) {
        Quickshell.execDetached(["hyprctl", "eval", hidden ? "hl.config({ cursor = { invisible = true } })" : root.cursorUnhideLua]);
    }

    Process { // Hide first, and only arm the capture once hyprctl has acknowledged it
        running: true
        command: ["hyprctl", "eval", "hl.config({ cursor = { invisible = true } })"]
        onExited: cursorSettleTimer.start()
    }

    Timer { // One compositor frame of slack so the pointer is really gone from the buffer
        id: cursorSettleTimer
        interval: 50
        onTriggered: root.captureArmed = true
    }

    Component.onDestruction: root.setCursorHidden(false)

    ScreencopyView { // Frozen screen content
        id: screencopy
        width: root.width
        height: root.height

        x: root.contentX
        y: root.contentY
        scale: root.contentScale
        transformOrigin: Item.TopLeft

        live: false
        paintCursor: false // The real pointer stays on top; a frozen copy of it would be a second cursor
        captureSource: root.captureArmed ? root.screen : null

        onHasContentChanged: if (hasContent)
            root.setCursorHidden(false)

        Behavior on scale {
            enabled: !root.panning
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }
        Behavior on x {
            enabled: !root.panning
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }
        Behavior on y {
            enabled: !root.panning
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }
    }

    // Dim everything but the spotlight
    Shape {
        anchors.fill: parent
        visible: root.dimEnabled && screencopy.hasContent
        opacity: root.dimEnabled ? 1 : 0
        preferredRendererType: Shape.CurveRenderer
        asynchronous: false

        Behavior on opacity {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }

        ShapePath {
            fillRule: ShapePath.OddEvenFill
            fillColor: ColorUtils.transparentize("black", 0.55)
            strokeWidth: -1

            PathMove {
                x: 0
                y: 0
            }
            PathLine {
                x: root.width
                y: 0
            }
            PathLine {
                x: root.width
                y: root.height
            }
            PathLine {
                x: 0
                y: root.height
            }
            PathLine {
                x: 0
                y: 0
            }

            PathAngleArc {
                centerX: spotlight.x + spotlight.width / 2
                centerY: spotlight.y + spotlight.height / 2
                radiusX: root.displayRadius
                radiusY: root.displayRadius
                startAngle: 0
                sweepAngle: 360
            }
        }
    }

    // The ring itself
    Rectangle {
        id: spotlight
        visible: screencopy.hasContent
        width: root.displayRadius * 2
        height: width
        radius: width / 2
        x: root.cursorX - width / 2
        y: root.cursorY - height / 2
        color: "transparent"
        border.width: 3
        border.color: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.3)
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: pressed ? Qt.ClosedHandCursor : Qt.ArrowCursor

        property real lastX: 0
        property real lastY: 0

        onPositionChanged: mouse => {
            root.cursorX = mouse.x;
            root.cursorY = mouse.y;
            if (root.panning) {
                root.contentX += mouse.x - lastX;
                root.contentY += mouse.y - lastY;
                root.clampOffsets();
                lastX = mouse.x;
                lastY = mouse.y;
            }
        }

        onPressed: mouse => {
            if (mouse.button === Qt.RightButton) {
                root.dismiss();
                return;
            }
            lastX = mouse.x;
            lastY = mouse.y;
            root.panning = true;
        }

        onReleased: root.panning = false
        onCanceled: root.panning = false

        onWheel: event => {
            // Follow how far the wheel actually turned, so a fast flick or a touchpad swipe
            // moves proportionally instead of one fixed step per event
            const steps = event.angleDelta.y !== 0 ? event.angleDelta.y / 120 : event.pixelDelta.y / 50;
            if (steps === 0)
                return;
            if (event.modifiers & Qt.ControlModifier) {
                // Resize the pointer ring instead of zooming
                const radius = root.spotlightRadius * Math.pow(root.ringStep, steps * -1);
                root.spotlightRadius = Math.min(root.maxSpotlightRadius, Math.max(root.minSpotlightRadius, radius));
                return;
            }
            root.cursorX = event.x;
            root.cursorY = event.y;
            root.zoomAt(event.x, event.y, Math.pow(root.zoomStep, steps));
        }
    }

    Item { // Keyboard handling
        anchors.fill: parent
        focus: true

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape || event.key === Qt.Key_Q) {
                root.dismiss();
            } else if (event.key === Qt.Key_Plus || event.key === Qt.Key_Equal) {
                root.zoomAt(root.cursorX, root.cursorY, root.zoomStep);
            } else if (event.key === Qt.Key_Minus) {
                root.zoomAt(root.cursorX, root.cursorY, 1 / root.zoomStep);
            } else if (event.key === Qt.Key_0 || event.key === Qt.Key_R) {
                root.reset();
            } else if (event.key === Qt.Key_D) {
                root.dimEnabled = !root.dimEnabled;
            } else {
                return;
            }
            event.accepted = true;
        }
    }

    // Fading hint
    Rectangle {
        id: hint
        visible: screencopy.hasContent
        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: parent.bottom
            bottomMargin: Appearance.sizes.elevationMargin * 2
        }
        implicitWidth: hintText.implicitWidth + 32
        implicitHeight: hintText.implicitHeight + 16
        radius: Appearance.rounding.full
        color: Appearance.colors.colLayer0

        StyledText {
            id: hintText
            anchors.centerIn: parent
            color: Appearance.colors.colOnLayer0
            font.pixelSize: Appearance.font.pixelSize.smaller
            text: "Scroll to zoom · Drag to pan · Ctrl+Scroll ring size · D dim · R reset · Esc close"
        }

        opacity: 1
        SequentialAnimation on opacity {
            running: screencopy.hasContent
            PauseAnimation {
                duration: 4000
            }
            NumberAnimation {
                to: 0
                duration: Appearance.animation.elementMoveExit.duration
                easing.type: Appearance.animation.elementMoveExit.type
                easing.bezierCurve: Appearance.animation.elementMoveExit.bezierCurve
            }
        }
    }
}
