import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.m3 as M3
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.UPower

Rectangle {
    id: root

    property var screen: root.QsWindow.window?.screen
    property var brightnessMonitor: Brightness.getMonitorForScreen(screen)

    implicitWidth: contentItem.implicitWidth + root.horizontalPadding * 2
    implicitHeight: contentItem.implicitHeight + root.verticalPadding * 2
    radius: Appearance.rounding.normal
    color: Appearance.colors.colLayer1
    property real verticalPadding: Appearance.sizes.m3QuickSlidersVerticalPadding
    property real horizontalPadding: Appearance.sizes.m3QuickSlidersHorizontalPadding

    Column {
        id: contentItem
        anchors {
            fill: parent
            leftMargin: root.horizontalPadding
            rightMargin: root.horizontalPadding
            topMargin: root.verticalPadding
            bottomMargin: root.verticalPadding
        }

        Loader {
            anchors {
                left: parent.left
                right: parent.right
            }
            visible: active
            active: Config.options.sidebar.quickSliders.showBrightness
            sourceComponent: QuickSlider {
                enabled: !!root.brightnessMonitor
                materialIcon: "light_mode"
                secondaryMaterialIcon: "wb_twilight"
                stopIndicatorValues: Hyprsunset.gamma !== 100 && (root.brightnessMonitor?.brightness ?? 0) !== 0 ? [0.3 + root.brightnessMonitor?.brightness * 0.7] : []
                value: Hyprsunset.gamma === 100? 0.3 + (root.brightnessMonitor?.brightness ?? 0) * 0.7 : (Hyprsunset.gamma - Hyprsunset.gammaLowerLimit) / (100 - Hyprsunset.gammaLowerLimit) * 0.3
                tooltipContent: Hyprsunset.gamma === 100 ? `${Math.round((root.brightnessMonitor?.brightness ?? 0) * 100)}%` : `${"Gamma"} ${Hyprsunset.gamma}%`
                onMoved: {
                    if (value >= 0.3) {
                        // 0.3 - 1.0 brightness
                        root.brightnessMonitor.setBrightness((value - 0.3) / 0.7);
                        if (Hyprsunset.gamma !== 100) {
                            Hyprsunset.setGamma(100);
                        }
                    } else {
                        // 0 - 0.3 gamma
                        if (root.brightnessMonitor.brightness !== 0) {
                            root.brightnessMonitor.setBrightness(0);
                        }
                        Hyprsunset.setGamma((value / 0.3 * (100 - Hyprsunset.gammaLowerLimit) + Hyprsunset.gammaLowerLimit));
                    }
                }
            }
        }

        Loader {
            anchors {
                left: parent.left
                right: parent.right
            }
            visible: active
            active: Config.options.sidebar.quickSliders.showVolume
            sourceComponent: QuickSlider {
                materialIcon: "volume_up"
                enabled: !!Audio.sink?.audio
                value: Audio.sink?.audio?.volume ?? 0
                onMoved: {
                    if (Audio.sink?.audio)
                        Audio.sink.audio.volume = value
                }
            }
        }

        Loader {
            anchors {
                left: parent.left
                right: parent.right
            }
            visible: active
            active: Config.options.sidebar.quickSliders.showMic
            sourceComponent: QuickSlider {
                materialIcon: "mic"
                enabled: !!Audio.source?.audio
                value: Audio.source?.audio?.volume ?? 0
                onMoved: {
                    if (Audio.source?.audio)
                        Audio.source.audio.volume = value
                }
            }
        }
    }

    component QuickSlider: M3.Slider {
        configuration: M3.Slider.Configuration.M
        stopIndicatorValues: []
        dividerValues: secondaryMaterialIcon.length > 0 ? [secondaryIconPosition] : []
    }
}
