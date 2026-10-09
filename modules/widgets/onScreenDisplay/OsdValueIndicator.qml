import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.m3 as M3

Item {
    id: root

    required property real value
    required property string icon
    required property string name
    property bool rotateIcon: false
    property bool scaleIcon: false
    property alias from: valueProgressBar.from
    property alias to: valueProgressBar.to
    property real valueIndicatorVerticalPadding: Appearance.sizes.osdVerticalPadding
    property real valueIndicatorLeftPadding: Appearance.sizes.osdLeftPadding
    property real valueIndicatorRightPadding: Appearance.sizes.osdRightPadding // An icon is circle ish, a column isn't, hence the extra padding

    implicitWidth: Appearance.sizes.osdWidth + 2 * Appearance.sizes.elevationMargin
    implicitHeight: valueIndicator.implicitHeight + 2 * Appearance.sizes.elevationMargin

    M3.Card {
        id: valueIndicator

        variant: "elevated"
        shape: "round"
        padding: 0

        anchors {
            fill: parent
            margins: Appearance.sizes.elevationMargin
        }

        // Icon on the left, stuff on the right
        RowLayout {
            id: valueRow

            Layout.fillWidth: true
            spacing: Appearance.sizes.osdIconGap

            Item {
                implicitWidth: Appearance.sizes.osdIconSize
                implicitHeight: Appearance.sizes.osdIconSize
                Layout.alignment: Qt.AlignVCenter
                Layout.leftMargin: valueIndicatorLeftPadding
                Layout.topMargin: valueIndicatorVerticalPadding
                Layout.bottomMargin: valueIndicatorVerticalPadding

                // Icon
                MaterialSymbol {
                    color: valueIndicator.contentColor
                    renderType: Text.QtRendering
                    text: root.icon
                    iconSize: Appearance.sizes.osdIconMinSize + (Appearance.sizes.osdIconSize - Appearance.sizes.osdIconMinSize) * (root.scaleIcon ? value : 1)
                    rotation: 180 * (root.rotateIcon ? value : 0)

                    anchors {
                        centerIn: parent
                        alignWhenCentered: !root.rotateIcon
                    }

                    Behavior on iconSize {
                        animation: Appearance.animation.elementMoveEnter.numberAnimation.createObject(this)
                    }

                    Behavior on rotation {
                        animation: Appearance.animation.elementMoveEnter.numberAnimation.createObject(this)
                    }

                }

            }
            // Stuff

            ColumnLayout {
                Layout.alignment: Qt.AlignVCenter
                Layout.fillWidth: true
                Layout.rightMargin: valueIndicatorRightPadding
                spacing: Appearance.sizes.osdContentGap

                // Name fill left, value on the right end
                RowLayout {
                    Layout.leftMargin: valueProgressBar.height / 2 // Align text with progressbar radius curve's left end
                    Layout.rightMargin: valueProgressBar.height / 2 // Align text with progressbar radius curve's left end

                    StyledText {
                        color: valueIndicator.contentColor
                        font.pixelSize: Appearance.font.pixelSize.small
                        Layout.fillWidth: true
                        text: root.name
                    }

                    StyledText {
                        color: valueIndicator.contentColor
                        font.pixelSize: Appearance.font.pixelSize.small
                        Layout.fillWidth: false
                        text: Math.round(root.value * 100)
                    }

                }

                M3.LinearProgressIndicator {
                    id: valueProgressBar

                    Layout.fillWidth: true
                    value: root.value
                }

            }

        }

    }

}
