import QtQuick
import QtQuick.Layouts
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.waffle.looks

BarButton {
    id: root

    checked: GlobalStates.sidebarLeftOpen
    onClicked: {
        GlobalStates.sidebarLeftOpen = !GlobalStates.sidebarLeftOpen;
    }

    contentItem: Item {
        anchors.fill: parent
        implicitHeight: column.implicitHeight
        implicitWidth: column.implicitWidth
        Row {
            id: column
            anchors {
                top: parent.top
                bottom: parent.bottom
                horizontalCenter: parent.horizontalCenter
            }
            spacing: 4

            IconHoverArea {
                id: internetHoverArea
                iconItem: FluentIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    icon: "wifi-1"
                    color: Looks.colors.inactiveIcon

                    FluentIcon {
                        anchors.fill: parent
                        icon: WIcons.internetIcon
                    }
                }
            }

            IconHoverArea {
                id: volumeHoverArea
                iconItem: FluentIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    icon: "speaker"
                    color: Looks.colors.inactiveIcon
                    
                    FluentIcon {
                        anchors.fill: parent
                        icon: WIcons.volumeIcon
                    }
                }
                onScrollDown: Audio.decrementVolume();
                onScrollUp: Audio.incrementVolume();
            }

            IconHoverArea {
                id: batteryHoverArea
                visible: Battery?.available ?? false
                iconItem: FluentIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    icon: WIcons.batteryLevelIcon
                    FluentIcon {
                        anchors.fill: parent
                        icon: WIcons.batteryIcon
                    }
                }
            }
        }
    }

    component IconHoverArea: FocusedScrollMouseArea {
        id: hoverArea
        required property var iconItem
        anchors {
            top: parent.top
            bottom: parent.bottom
        }
        hoverEnabled: true
        implicitHeight: hoverArea.iconItem.implicitHeight
        implicitWidth: hoverArea.iconItem.implicitWidth

        onPressed: (event) => event.accepted = false; // Don't consume clicks

        children: [iconItem]
    }

    BarToolTip {
        extraVisibleCondition: root.shouldShowTooltip && internetHoverArea.containsMouse
        text: "%1\nInternet access".arg(Network.ethernet ? "Network" : Network.networkName)
    }
    BarToolTip {
        extraVisibleCondition: root.shouldShowTooltip && volumeHoverArea.containsMouse
        text: "Speakers (%1): %2" //
            .arg(Audio.sink?.nickname || Audio.sink?.description || "Unknown") //
            .arg(Audio.sink?.audio.muted ? "Muted" : `${Math.round(Audio.sink?.audio.volume * 100) || 0}%`) //
    }
    BarToolTip {
        extraVisibleCondition: root.shouldShowTooltip && batteryHoverArea.containsMouse
        text: "Battery: %1%2" //
            .arg(`${Math.round(Battery.percentage * 100) || 0}%`) //
            .arg(Battery.isPluggedIn ? (" " + "(Plugged in)") : "")
    }
}
