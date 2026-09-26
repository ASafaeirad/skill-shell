import qs.modules.common
import qs.modules.common.functions
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    property real padding: 5
    property bool shimmer: false
    implicitWidth: gridLayout.implicitWidth + padding * 2
    implicitHeight: Appearance.sizes.baseBarHeight
    default property alias items: gridLayout.children

    Rectangle {
        id: background
        anchors {
            fill: parent
            topMargin: Appearance.spacing.s
            bottomMargin: Appearance.spacing.s
        }
        color: Config.options?.bar.borderless ? "transparent" : Appearance.colors.colLayer1
        radius: Appearance.rounding.small
    }

    GridLayout {
        id: gridLayout
        columns: -1
        rows: 1
        anchors {
            verticalCenter: parent.verticalCenter
            left: parent.left
            right: parent.right
            margins: root.padding
        }
        columnSpacing: 4
        rowSpacing: 12
    }

    Item {
        id: shimmerOverlay
        anchors.fill: background
        visible: opacity > 0
        opacity: root.shimmer ? 1.0 : 0.0

        Behavior on opacity {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }

        layer.enabled: true
        layer.effect: OpacityMask {
            maskSource: Rectangle {
                width: background.width
                height: background.height
                radius: background.radius
            }
        }

        Rectangle {
            id: shimmerBand
            width: Math.max(shimmerOverlay.width * 0.75, 40)
            height: shimmerOverlay.height * 2
            anchors.verticalCenter: parent.verticalCenter
            rotation: 15

            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop {
                    position: 0.0
                    color: "transparent"
                }
                GradientStop {
                    position: 0.5
                    color: ColorUtils.applyAlpha(Appearance.colors.colOnLayer1, 0.28)
                }
                GradientStop {
                    position: 1.0
                    color: "transparent"
                }
            }

            NumberAnimation on x {
                running: root.shimmer
                loops: Animation.Infinite
                from: -shimmerBand.width * 1.5
                to: shimmerOverlay.width + shimmerBand.width * 0.5
                duration: 1200
                easing.type: Easing.InOutQuad
            }
        }
    }
}

