pragma ComponentBehavior: Bound
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Layouts

/**
 * Material 3 slider.
 * https://m3.material.io/components/sliders
 *
 *   M3.Slider { value: Audio.volume; onMoved: Audio.setVolume(value); configuration: M3.Slider.Configuration.M }
 *
 * configuration: the track size, M3.Slider.Configuration.{XS, S (default), M, L, XL, Wavy}.
 * materialIcon and secondaryMaterialIcon draw trailing icons. secondaryIconPosition
 * is normalized to the range (default 0.3); dividerValues can mark that position.
 * Icon presentation is for horizontal, non-mirrored sliders.
 * It doesn't exactly match the spec because the spec sizes are too large on a desktop.
 * Should be at 3/4 scale...
 */
QQC.Slider {
    id: root

    // Icons follow the handle when the active track reaches their resting position.
    property string materialIcon: ""
    property string secondaryMaterialIcon: ""
    property real secondaryIconPosition: 0.3

    property list<real> stopIndicatorValues: [1]
    property list<real> dividerValues: []
    enum Configuration {
        Wavy = 4,
        XS = 12,
        S = 18,
        M = 30,
        L = 42,
        XL = 72
    }

    property var configuration: Slider.Configuration.S

    property real handleDefaultWidth: 3
    property real handlePressedWidth: 1.5
    property color highlightColor: enabled ? Appearance.colors.colPrimary : ColorUtils.applyAlpha(Appearance.m3colors.m3onSurface, Appearance.stateLayer.disabledContent)
    property color trackColor: enabled ? Appearance.colors.colSecondaryContainer : ColorUtils.applyAlpha(Appearance.m3colors.m3onSurface, Appearance.stateLayer.disabledContainer)
    property color handleColor: enabled ? Appearance.colors.colPrimary : ColorUtils.applyAlpha(Appearance.m3colors.m3onSurface, Appearance.stateLayer.disabledContent)
    property color dotColor: enabled ? Appearance.m3colors.m3onSecondaryContainer : ColorUtils.applyAlpha(Appearance.m3colors.m3onSurface, Appearance.stateLayer.disabledContent)
    property color dotColorHighlighted: enabled ? Appearance.m3colors.m3onPrimary : ColorUtils.applyAlpha(Appearance.m3colors.m3onSurface, Appearance.stateLayer.disabledContent)
    property real unsharpenRadius: Appearance.rounding.unsharpen
    property real trackWidth: configuration
    property real trackRadius: trackWidth >= Slider.Configuration.XL ? 21
        : trackWidth >= Slider.Configuration.L ? 12
        : trackWidth >= Slider.Configuration.M ? 9
        : trackWidth >= Slider.Configuration.S ? 6
        : height / 2
    property real handleHeight: (configuration === Slider.Configuration.Wavy) ? 24 : Math.max(33, trackWidth + 9)
    property real handleWidth: root.pressed ? handlePressedWidth : handleDefaultWidth
    property real handleMargins: 4
    property real dividerMargins: 2
    property real trackDotSize: 3
    property bool usePercentTooltip: true
    property string tooltipContent: usePercentTooltip ? `${Math.round(((value - from) / (to - from)) * 100)}%` : `${Math.round(value)}`
    property bool wavy: configuration === Slider.Configuration.Wavy // If true, the progress bar will have a wavy fill effect
    property bool animateWave: true
    property real waveAmplitudeMultiplier: wavy ? 0.5 : 0
    property real waveFrequency: 6
    property real waveFps: 60

    leftPadding: handleMargins
    rightPadding: handleMargins
    property real effectiveDraggingWidth: width - leftPadding - rightPadding

    Layout.fillWidth: true
    from: 0
    to: 1

    Behavior on value { // This makes the adjusted value (like volume) shift smoothly
        SmoothedAnimation {
            velocity: Appearance.animation.elementMoveFast.velocity
        }
    }

    Behavior on handleMargins {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }

    component TrackDot: Rectangle {
        required property real value
        property real normalizedValue: (value - root.from) / (root.to - root.from)
        anchors.verticalCenter: parent.verticalCenter
        x: root.handleMargins + (normalizedValue * root.effectiveDraggingWidth) - (root.trackDotSize / 2)
        width: root.trackDotSize
        height: root.trackDotSize
        radius: Appearance.rounding.full
        color: normalizedValue > root.visualPosition ? root.dotColor : root.dotColorHighlighted

        Behavior on color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }
    }

    MouseArea {
        anchors.fill: parent
        onPressed: (mouse) => mouse.accepted = false
        cursorShape: root.pressed ? Qt.ClosedHandCursor : Qt.PointingHandCursor 
    }

    background: Item {
        id: background
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: parent.horizontalCenter
        width: root.width
        implicitHeight: trackWidth
        property var normalized: root.dividerValues.map(v => (v - root.from) / (root.to - root.from))
        property var filtered: normalized.filter(v => Math.abs(v - root.visualPosition) * effectiveDraggingWidth > handleMargins + handleWidth / 2 - dividerMargins)
        property var leftValues: [0, ...filtered.filter(v => v < root.visualPosition), root.visualPosition]
        property var rightValues: [root.visualPosition, ...filtered.filter(v => v > root.visualPosition), 1]
        property var leftWidths: leftValues.map((v, i, a) => a[i + 1] - v).slice(0, -1)
        property var rightWidths: rightValues.map((v, i, a) => a[i + 1] - v).slice(0, -1)

        // Fill left
        Repeater {
            model: background.leftWidths.length

            Loader {
                required property real index
                anchors.verticalCenter: background.verticalCenter
                property real leftMargin: index > 0 ? root.dividerMargins : 0
                property real rightMargin: index < background.leftWidths.length - 1 ? root.dividerMargins : root.handleMargins
                x: background.leftValues[index] * root.effectiveDraggingWidth + leftMargin + (index > 0 ? leftPadding : 0)
                width: background.leftWidths[index] * root.effectiveDraggingWidth - leftMargin - rightMargin - (index === background.leftWidths.length - 1 ? handleWidth / 2 : 0) + (index === 0 ? leftPadding : 0)
                height: root.trackWidth
                active: !root.wavy
                sourceComponent: Rectangle {
                    color: root.highlightColor
                    topLeftRadius: index === 0 ? root.trackRadius : root.unsharpenRadius
                    bottomLeftRadius: index === 0 ? root.trackRadius : root.unsharpenRadius
                    topRightRadius: root.unsharpenRadius
                    bottomRightRadius: root.unsharpenRadius
                }
            }
        }

        Repeater {
            model: background.leftWidths.length

            Loader {
                required property int index
                anchors.verticalCenter: background.verticalCenter
                property real leftMargin: index > 0 ? root.dividerMargins : 0
                property real rightMargin: index < background.leftWidths.length - 1 ? root.dividerMargins : root.handleMargins
                x: background.leftValues[index] * root.effectiveDraggingWidth + leftMargin + (index > 0 ? leftPadding : 0)
                width: background.leftWidths[index] * root.effectiveDraggingWidth - leftMargin - rightMargin - (index === background.leftWidths.length - 1 ? handleWidth / 2 : 0) + (index === 0 ? leftPadding : 0)
                height: root.height
                active: root.wavy
                sourceComponent: WavyLine {
                    id: wavyFill
                    frequency: root.waveFrequency
                    fullLength: root.width
                    color: root.highlightColor
                    amplitudeMultiplier: root.wavy ? 0.5 : 0
                    width: parent.width
                    height: root.trackWidth
                    Connections {
                        target: root
                        function onValueChanged() { wavyFill.requestPaint(); }
                        function onHighlightColorChanged() { wavyFill.requestPaint(); }
                    }
                    FrameAnimation {
                        running: root.animateWave
                        onTriggered: {
                            wavyFill.requestPaint()
                        }
                    }
                }
            }
        }

        // Fill right
        Repeater {
            model: background.rightWidths.length

            Rectangle {
                required property int index
                anchors.verticalCenter: background.verticalCenter
                property real leftMargin: index > 0 ? root.dividerMargins : root.handleMargins
                property real rightMargin: index < background.rightWidths.length - 1 ? root.dividerMargins : 0
                x: background.rightValues[index] * root.effectiveDraggingWidth + leftMargin + (index === 0 ? handleWidth / 2 : 0) + leftPadding
                width: background.rightWidths[index] * root.effectiveDraggingWidth - leftMargin - rightMargin - (index === 0 ? handleWidth / 2 : 0) + (index === background.rightWidths.length - 1 ? rightPadding : 0)
                height: trackWidth
                color: root.trackColor
                topRightRadius: index === background.rightWidths.length - 1 ? root.trackRadius : root.unsharpenRadius
                bottomRightRadius: index === background.rightWidths.length - 1 ? root.trackRadius : root.unsharpenRadius
                topLeftRadius: root.unsharpenRadius
                bottomLeftRadius: root.unsharpenRadius
            }
        }

        // Stop indicators
        Repeater {
            model: root.stopIndicatorValues
            TrackDot {
                required property real modelData
                value: modelData
                anchors.verticalCenter: parent?.verticalCenter
            }
        }
    }

    MaterialSymbol {
        visible: root.orientation === Qt.Horizontal && !root.mirrored && root.materialIcon.length > 0
        property bool nearFull: root.position >= 1 - Appearance.sizes.m3SliderIconThreshold
        anchors {
            verticalCenter: root.verticalCenter
            right: nearFull ? root.handle.right : root.right
            rightMargin: nearFull ? Appearance.sizes.m3SliderIconHandleMargin : Appearance.sizes.m3SliderIconEdgeMargin
        }
        iconSize: Appearance.sizes.m3SliderIconSize
        color: !root.enabled ? ColorUtils.applyAlpha(Appearance.m3colors.m3onSurface, Appearance.stateLayer.disabledContent)
            : nearFull ? Appearance.colors.colOnPrimary : Appearance.colors.colOnSecondaryContainer
        text: root.materialIcon
        Behavior on color { animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this) }
        Behavior on anchors.rightMargin { animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this) }
    }

    MaterialSymbol {
        visible: root.orientation === Qt.Horizontal && !root.mirrored && root.secondaryMaterialIcon.length > 0
        property bool nearIcon: root.secondaryIconPosition - root.position <= Appearance.sizes.m3SliderIconThreshold
            && root.secondaryIconPosition - root.position > (root.handleWidth + Appearance.sizes.m3SliderIconEdgeMargin - Appearance.sizes.m3SliderIconHandleMargin) / root.effectiveDraggingWidth
        anchors {
            verticalCenter: root.verticalCenter
            right: nearIcon ? root.handle.right : root.right
            rightMargin: nearIcon ? Appearance.sizes.m3SliderIconHandleMargin
                : (1 - root.secondaryIconPosition) * root.effectiveDraggingWidth + root.rightPadding + Appearance.sizes.m3SliderIconEdgeMargin
        }
        iconSize: Appearance.sizes.m3SliderIconSize
        color: !root.enabled ? ColorUtils.applyAlpha(Appearance.m3colors.m3onSurface, Appearance.stateLayer.disabledContent)
            : root.position >= root.secondaryIconPosition - Appearance.sizes.m3SliderIconThreshold ? Appearance.colors.colOnPrimary : Appearance.colors.colOnSecondaryContainer
        text: root.secondaryMaterialIcon
        Behavior on color { animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this) }
    }

    handle: Rectangle {
        id: handle

        implicitWidth: root.handleWidth
        implicitHeight: root.handleHeight
        x: root.leftPadding + (root.visualPosition * root.effectiveDraggingWidth) - (root.handleWidth / 2)
        anchors.verticalCenter: parent.verticalCenter
        radius: Appearance.rounding.full
        color: root.handleColor

        Behavior on implicitWidth {
            animation: Appearance?.animation.elementMoveFast.numberAnimation.createObject(this)
        }

        StyledToolTip {
            extraVisibleCondition: root.pressed
            text: root.tooltipContent
            font {
                family: Appearance.font.family.numbers
                variableAxes: Appearance.font.variableAxes.numbers
            }
        }
    }
}
