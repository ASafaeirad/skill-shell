import QtQuick
import qs.modules.common
import qs.modules.common.widgets

/**
 * Material 3 floating action button.
 * https://m3.material.io/components/floating-action-button
 *
 *   M3.Fab { iconText: "add"; tooltip: "New"; onClicked: ... }
 *
 * variant: "primary" (default) | "secondary" | "tertiary"; the container
 *   colour role. A FAB paired with a toolbar is "tertiary".
 * size: "regular" (default, 56) | "toolbar" (48, beside a floating M3.Toolbar)
 * elevated: draws the FAB's shadow.
 * expanded + buttonText: the extended FAB, with the label revealed beside the icon.
 * colBackground, colBackgroundHover, colRipple, colOnBackground override the
 *   variant's colours; baseSize overrides size.
 */
RippleButton {
    id: root

    property string variant: "primary"
    property string size: "regular"
    property bool elevated: false
    property string tooltip: ""
    property string iconText: "add"
    property bool expanded: false
    property real baseSize: size === "toolbar" ? Appearance.sizes.m3ToolbarFabSize : Appearance.sizes.m3FabSize
    property real elementSpacing: 5
    property color colOnBackground: variant === "tertiary" ? Appearance.colors.colOnTertiaryContainer
        : variant === "secondary" ? Appearance.colors.colOnSecondaryContainer
        : Appearance.colors.colOnPrimaryContainer

    implicitWidth: expanded ? (Math.max(contentRowLayout.implicitWidth + 10 * 2, baseSize)) : baseSize
    implicitHeight: baseSize
    buttonRadius: baseSize / 14 * 4
    colBackground: variant === "tertiary" ? Appearance.colors.colTertiaryContainer
        : variant === "secondary" ? Appearance.colors.colSecondaryContainer
        : Appearance.colors.colPrimaryContainer
    colBackgroundHover: variant === "tertiary" ? Appearance.colors.colTertiaryContainerHover
        : variant === "secondary" ? Appearance.colors.colSecondaryContainerHover
        : Appearance.colors.colPrimaryContainerHover
    colRipple: variant === "tertiary" ? Appearance.colors.colTertiaryContainerActive
        : variant === "secondary" ? Appearance.colors.colSecondaryContainerActive
        : Appearance.colors.colPrimaryContainerActive

    contentItem: Row {
        id: contentRowLayout
        property real horizontalMargins: (root.baseSize - icon.width) / 2
        anchors {
            verticalCenter: parent?.verticalCenter
            left: parent?.left
            leftMargin: contentRowLayout.horizontalMargins
        }
        spacing: 0

        MaterialSymbol {
            id: icon
            anchors.verticalCenter: parent.verticalCenter
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            iconSize: 26
            color: root.colOnBackground
            text: root.iconText
        }
        Loader {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.buttonText?.length > 0
            active: true
            sourceComponent: Revealer {
                visible: root.expanded || implicitWidth > 0
                reveal: root.expanded
                implicitWidth: reveal ? (buttonText.implicitWidth + root.elementSpacing + contentRowLayout.horizontalMargins) : 0
                // Revealer sizes itself from childrenRect, which depends on this
                // height through the label's vertical anchor: a binding loop.
                implicitHeight: buttonText.implicitHeight
                StyledText {
                    id: buttonText
                    anchors {
                        left: parent.left
                        leftMargin: root.elementSpacing
                        verticalCenter: parent.verticalCenter
                    }
                    text: root.buttonText
                    color: root.colOnBackground
                    font.pixelSize: 14
                    font.weight: 450
                }
            }
        }
    }

    StyledRectangularShadow {
        z: -2
        visible: root.elevated
        target: root.background
    }

    StyledToolTip {
        text: root.tooltip
        extraVisibleCondition: root.tooltip.length > 0
    }
}
