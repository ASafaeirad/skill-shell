import QtQuick
import QtQuick.Shapes
import qs.modules.common

/**
 * Material 3 circular progress. See https://m3.material.io/components/progress-indicators/specs
 */
Item {
    id: root

    property int implicitSize: Appearance.sizes.circularProgressSize
    property int lineWidth: Appearance.sizes.progressBarHeight
    property real value: 0
    property bool indeterminate: false
    property color colPrimary: Appearance.m3colors.m3primary
    property color colSecondary: Appearance.m3colors.m3surfaceContainerHighest
    property real gapAngle: 360 / 18
    property bool fill: false
    property bool drainClockwise: false
    property int fillOverflow: 2
    property bool enableAnimation: true
    property int animationDuration: Appearance.animation.elementMove.duration
    property var easingType: Easing.OutCubic
    property real degree: Math.max(0, Math.min(1, value || 0)) * 360
    property real centerX: root.width / 2
    property real centerY: root.height / 2
    property real arcRadius: root.implicitSize / 2 - root.lineWidth
    property real startAngle: -90
    property real indeterminateSweep: 60

    implicitWidth: implicitSize
    implicitHeight: implicitSize

    SequentialAnimation on indeterminateSweep {
        running: root.visible && root.indeterminate
        loops: Animation.Infinite
        NumberAnimation {
            from: 30
            to: 270
            duration: Appearance.animation.elementMove.duration * 2
            easing.type: Easing.InOutCubic
        }
        NumberAnimation {
            from: 270
            to: 30
            duration: Appearance.animation.elementMove.duration * 2
            easing.type: Easing.InOutCubic
        }
    }

    Loader {
        active: root.fill
        anchors.fill: parent

        sourceComponent: Rectangle {
            radius: 9999
            color: root.colSecondary
        }

    }

    Shape {
        anchors.fill: parent
        rotation: root.indeterminate ? indeterminateRotation.angle : 0
        layer.enabled: true
        layer.smooth: true
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            id: secondaryPath

            strokeColor: root.colSecondary
            strokeWidth: root.lineWidth
            capStyle: ShapePath.RoundCap
            fillColor: "transparent"

            PathAngleArc {
                centerX: root.centerX
                centerY: root.centerY
                radiusX: root.arcRadius
                radiusY: root.arcRadius
                startAngle: root.drainClockwise ? root.startAngle : root.startAngle - root.gapAngle
                sweepAngle: root.indeterminate ? 0 : root.drainClockwise
                    ? Math.max(0, 360 - root.degree - root.gapAngle)
                    : -Math.max(0, 360 - root.degree - 2 * root.gapAngle)
            }

        }

        ShapePath {
            id: primaryPath

            strokeColor: root.colPrimary
            strokeWidth: root.lineWidth
            capStyle: ShapePath.RoundCap
            fillColor: "transparent"

            PathAngleArc {
                centerX: root.centerX
                centerY: root.centerY
                radiusX: root.arcRadius
                radiusY: root.arcRadius
                startAngle: root.startAngle + (root.indeterminate ? 0 : root.drainClockwise ? 360 - root.degree : 0)
                sweepAngle: root.indeterminate ? root.indeterminateSweep : root.drainClockwise ? Math.max(0, root.degree - root.gapAngle) : root.degree
            }

        }

    }

    QtObject {
        id: indeterminateRotation
        property real angle: 0
        NumberAnimation on angle {
            running: root.visible && root.indeterminate
            loops: Animation.Infinite
            from: 0
            to: 360
            duration: Appearance.animation.elementMove.duration * 4
        }
    }

    Behavior on degree {
        enabled: root.enableAnimation

        NumberAnimation {
            duration: root.animationDuration
            easing.type: root.easingType
        }

    }

}
