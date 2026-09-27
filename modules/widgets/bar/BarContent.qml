import qs.modules.widgets.bar.weather
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower
import qs
import qs.services
import qs.modules.common
import qs.modules.common.m3 as M3
import qs.modules.common.widgets
import qs.modules.common.functions

Item { // Bar content region
    id: root

    property var screen: root.QsWindow.window?.screen
    property var brightnessMonitor: Brightness.getMonitorForScreen(screen)
    property real useShortenedForm: (Appearance.sizes.barHellaShortenScreenWidthThreshold >= screen?.width)
                                    ? 2 : (Appearance.sizes.barShortenScreenWidthThreshold >= screen?.width)
                                      ? 1 : 0
    readonly property int centerSideModuleWidth: (useShortenedForm == 2)
                                                 ? Appearance.sizes.barCenterSideModuleWidthHellaShortened : (
                                                       useShortenedForm == 1)
                                                   ? Appearance.sizes.barCenterSideModuleWidthShortened :
                                                     Appearance.sizes.barCenterSideModuleWidth

    // Background shadow
    Loader {
        active: Config.options.bar.showBackground && Config.options.bar.cornerStyle === 1
                && Config.options.bar.floatStyleShadow

        anchors.fill: barBackground
        sourceComponent: StyledRectangularShadow {
            anchors.fill: undefined // The loader's anchors act on this, and this should not have any anchor
            target: barBackground
        }
    }
    // Background
    Rectangle {
        id: barBackground
        anchors {
            fill: parent
            margins: Config.options.bar.cornerStyle === 1 ? (Appearance.sizes.hyprlandGapsOut) :
                                                            0 // idk why but +1 is needed
        }
        color: Config.options.bar.showBackground ? Appearance.colors.colLayer0 : "transparent"
        radius: Config.options.bar.cornerStyle === 1 ? Appearance.rounding.windowRounding : 0
        border.width: Config.options.bar.cornerStyle === 1 ? 1 : 0
        border.color: Appearance.colors.colLayer0Border
    }

    MouseArea { // Left side
        id: barLeftSideMouseArea

        anchors {
            top: parent.top
            bottom: parent.bottom
            left: parent.left
            right: middleSection.left
        }
        implicitWidth: leftSectionRowLayout.implicitWidth
        implicitHeight: Appearance.sizes.baseBarHeight

        RowLayout {
            id: leftSectionRowLayout
            anchors.fill: parent
            spacing: 0

            BarSection {
                section: "start"
                useShortenedForm: root.useShortenedForm
            }
        }
    }

    Row { // Middle section
        id: middleSection
        anchors {
            top: parent.top
            bottom: parent.bottom
            horizontalCenter: parent.horizontalCenter
        }
        spacing: 4

        // A Row gives its children no height, so this draws nothing — as the
        // separator it replaces didn't either.
        M3.Divider {
            vertical: true
            visible: Config.options?.bar.borderless
        }

        BarSection {
            section: "center"
            useShortenedForm: root.useShortenedForm
        }
    }

    MouseArea { // Right side
        id: barRightSideMouseArea

        anchors {
            top: parent.top
            bottom: parent.bottom
            left: middleSection.right
            right: parent.right
        }
        implicitWidth: rightSectionRowLayout.implicitWidth
        implicitHeight: Appearance.sizes.baseBarHeight

        hoverEnabled: true
        onPressed: event => {
            if (event.button === Qt.LeftButton) {
                GlobalStates.sidebarRight?.toggle();
            }
        }

        RowLayout {
            id: rightSectionRowLayout
            anchors.fill: parent
            spacing: 5

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }

            BarSection {
                section: "end"
                useShortenedForm: root.useShortenedForm
                areaHovered: barRightSideMouseArea.containsMouse
            }
        }
    }
}
