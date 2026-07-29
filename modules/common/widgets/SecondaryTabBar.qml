import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.models

TabBar {
    id: root

    property real indicatorPadding: 8

    Layout.fillWidth: true

    background: Item {
        WheelHandler {
            onWheel: (event) => {
                if (event.angleDelta.y < 0)
                    root.incrementCurrentIndex();
                else if (event.angleDelta.y > 0)
                    root.decrementCurrentIndex();
            }
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        }

        Rectangle {
            id: activeIndicator

            // Animation
            property real baseWidth: root.width / root.count

            z: 9999
            anchors.bottom: parent.bottom
            topLeftRadius: height
            topRightRadius: height
            bottomLeftRadius: 0
            bottomRightRadius: 0
            color: Appearance.colors.colPrimary
            height: 3
            x: Math.min(idxPair.idx1, idxPair.idx2) * baseWidth + root.indicatorPadding
            width: ((Math.max(idxPair.idx1, idxPair.idx2) + 1) * baseWidth - root.indicatorPadding) - x

            AnimatedTabIndexPair {
                id: idxPair

                index: root.currentIndex
            }

        }

        // Tabbar bottom border
        Rectangle {
            id: tabBarBottomBorder

            z: 9998
            anchors.bottom: parent.bottom
            height: 1
            color: Appearance.colors.colOutlineVariant

            anchors {
                left: parent.left
                right: parent.right
            }

        }

    }

}
