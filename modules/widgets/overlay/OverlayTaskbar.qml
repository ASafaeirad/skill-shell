pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.common.m3 as M3
import qs.modules.common.widgets.widgetCanvas

Rectangle {
    id: root

    property real padding: Appearance.spacing.s

    opacity: OverlayContext.overlayOpen ? 1 : 0
    implicitWidth: contentRow.implicitWidth + (padding * 2)
    implicitHeight: contentRow.implicitHeight + (padding * 2)
    color: Appearance.m3colors.m3surfaceContainer
    radius: Appearance.rounding.large
    border.color: Appearance.colors.colOutlineVariant
    border.width: Appearance.sizes.m3OutlineWidth

    Behavior on opacity {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }

    RowLayout {
        id: contentRow
        anchors {
            fill: parent
            margins: root.padding
        }
        spacing: Appearance.spacing.xs

        Row {
            spacing: Appearance.spacing.xxs * 2
            Repeater {
                model: ScriptModel {
                    values: OverlayContext.availableWidgets
                }
                delegate: M3.IconButton {
                    required property var modelData
                    materialIcon: modelData.materialSymbol
                    tooltip: modelData.identifier.replace(/([A-Z])/g, " $1").replace(/^./, str => str.toUpperCase())
                    toggleable: true
                    selectedVariant: "tonal"
                    selected: Persistent.states.overlay.open.includes(modelData.identifier)
                    altAction: () => OverlayContext.requestCenter(modelData.identifier)
                    onClicked: {
                        if (selected) {
                            Persistent.states.overlay.open = Persistent.states.overlay.open.filter(type => type !== modelData.identifier);
                        } else {
                            Persistent.states.overlay.open.push(modelData.identifier);
                        }
                    }
                }
            }
        }

        M3.Divider {
            vertical: true
            insetStart: Appearance.spacing.s + Appearance.spacing.xxs
            insetEnd: insetStart
        }
        TimeWidget {}
        M3.Divider {
            vertical: true
            insetStart: Appearance.spacing.s + Appearance.spacing.xxs
            insetEnd: insetStart
            visible: Battery.available
        }
        BatteryWidget {
            visible: Battery.available
        }
    }

    component TimeWidget: StyledText {
        Layout.alignment: Qt.AlignVCenter
        Layout.leftMargin: Appearance.spacing.s
        Layout.rightMargin: Appearance.spacing.xs

        text: DateTime.time
        color: Appearance.colors.colOnSurface
        font {
            family: Appearance.font.family.numbers
            variableAxes: Appearance.font.variableAxes.numbers
            pixelSize: Appearance.font.pixelSize.huge
        }
    }
    
    component BatteryWidget: Row {
        id: batteryWidget
        Layout.alignment: Qt.AlignVCenter
        Layout.leftMargin: Appearance.spacing.xs
        Layout.rightMargin: Appearance.spacing.xs
        spacing: Appearance.spacing.xxs
        property color colText: Battery.isLowAndNotCharging ? Appearance.colors.colError : Appearance.colors.colOnSurface

        MaterialSymbol {
            id: boltIcon
            anchors.verticalCenter: parent.verticalCenter
            fill: 1
            text: Battery.isCharging ? "bolt" : "battery_android_full"
            color: batteryWidget.colText
            iconSize: Appearance.font.pixelSize.hugeass
            animateChange: true
        }
        
        StyledText {
            id: batteryText
            anchors.verticalCenter: parent.verticalCenter
            text: Math.round(Battery.percentage * 100) + "%"
            color: batteryWidget.colText
            font {
                family: Appearance.font.family.numbers
                variableAxes: Appearance.font.variableAxes.numbers
                pixelSize: Appearance.font.pixelSize.large
            }
        }
    }

}
