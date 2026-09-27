pragma ComponentBehavior: Bound
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls


/**
 * Material 3 progress bar. See https://m3.material.io/components/progress-indicators/overview
 */
ProgressBar {
    id: root
    property real valueBarWidth: Appearance.sizes.progressBarWidth
    property real valueBarHeight: Appearance.sizes.progressBarHeight
    property real valueBarGap: valueBarHeight
    property color highlightColor: Appearance.m3colors.m3primary
    property color trackColor: Appearance.m3colors.m3surfaceContainerHighest
    property bool wavy: false // If true, the progress bar will have a wavy fill effect
    property bool animateWave: true
    property real waveAmplitudeMultiplier: wavy ? 0.75 : 0
    property real waveFrequency: 10
    property real waveSpeedMultiplier: 1.5
    property real waveLineWidth: valueBarHeight
    property real waveFps: 60
    property real indeterminatePosition: 0

    SequentialAnimation on indeterminatePosition {
        running: root.visible && root.indeterminate
        loops: Animation.Infinite
        NumberAnimation {
            from: -0.4
            to: 1
            duration: Appearance.animation.elementMove.duration * 4
            easing.type: Easing.InOutCubic
        }
    }

    Behavior on waveAmplitudeMultiplier {
        animation: Appearance?.animation.elementMoveFast.numberAnimation.createObject(this)
    }

    Behavior on value {
        animation: Appearance?.animation.elementMoveEnter.numberAnimation.createObject(this)
    }
    
    background: Item {
        implicitHeight: valueBarHeight
        implicitWidth: valueBarWidth
    }

    contentItem: Item {
        id: contentItem
        anchors.fill: parent

        Loader {
            anchors {
                left: parent.left
                verticalCenter: parent.verticalCenter
            }
            active: root.wavy && !root.indeterminate
            sourceComponent: WavyLine {
                id: wavyFill
                frequency: root.waveFrequency
                speedMultiplier: root.waveSpeedMultiplier
                color: root.highlightColor
                amplitudeMultiplier: root.waveAmplitudeMultiplier
                height: Math.max(contentItem.height, root.waveLineWidth) * 6
                width: contentItem.width * root.visualPosition
                lineWidth: root.waveLineWidth
                fullLength: root.width
                Connections {
                    target: root
                    function onValueChanged() { wavyFill.requestPaint(); }
                    function onHighlightColorChanged() { wavyFill.requestPaint(); }
                }
                FrameAnimation {
                    running: root.animateWave && root.visible && !root.indeterminate
                    onTriggered: {
                        wavyFill.requestPaint()
                    }
                }
            }
        }

        Loader {
            active: !root.wavy && !root.indeterminate
            sourceComponent: Rectangle {
                anchors.left: parent.left
                width: contentItem.width * root.visualPosition
                height: contentItem.height
                radius: height / 2
                color: root.highlightColor
            }
        }
        
        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: root.trackColor
            z: -1
            visible: root.indeterminate
        }

        Item {
            anchors.fill: parent
            clip: true
            visible: root.indeterminate

            Rectangle {
                x: parent.width * root.indeterminatePosition
                width: parent.width * 0.4
                height: parent.height
                radius: height / 2
                color: root.highlightColor
            }
        }

        Rectangle { // Right remaining part fill
            anchors.right: parent.right
            width: Math.max(0, (1 - root.visualPosition) * parent.width - root.valueBarGap)
            height: parent.height
            radius: height / 2
            color: root.trackColor
            visible: !root.indeterminate && root.visualPosition < 1
        }
        
        Rectangle { // Stop point
            anchors.right: parent.right
            width: root.valueBarGap
            height: root.valueBarGap
            radius: height / 2
            color: root.highlightColor
            visible: !root.indeterminate && root.visualPosition < 1
        }
    }
}
