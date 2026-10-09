import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

/**
 * Material 3 card: a container for one subject.
 * https://m3.material.io/components/cards
 *
 *   M3.Card {
 *       variant: "outlined"
 *       StyledText { text: "Title" }
 *       StyledText { text: "Body" }
 *   }
 *
 * Children stack in a ColumnLayout inset by `padding`.
 * variant: "filled" (default) | "elevated" | "outlined"
 * interactive: adds the hover state layer and emits clicked().
 * selected: controlled selection; selectedVariant is "tonal" or "filled".
 */
Rectangle {
    id: root

    property string variant: "filled"
    property bool interactive: false
    property bool selected: false
    property string selectedVariant: "tonal"
    property real padding: Appearance.spacing.lg
    property alias spacing: content.spacing
    default property alias contentData: content.data
    readonly property bool hovered: interactive && mouseArea.containsMouse
    readonly property bool pressed: interactive && mouseArea.pressed

    signal clicked()

    readonly property color containerColor: selected ? (selectedVariant === "filled" ? Appearance.colors.colPrimary : Appearance.colors.colSecondaryContainer)
        : variant === "elevated" ? Appearance.colors.colSurfaceContainerLow
        : variant === "outlined" ? "transparent"
        : Appearance.colors.colSurfaceContainerHighest
    readonly property color contentColor: selected ? (selectedVariant === "filled" ? Appearance.colors.colOnPrimary : Appearance.colors.colOnSecondaryContainer) : Appearance.colors.colOnSurface

    implicitWidth: content.implicitWidth + padding * 2
    implicitHeight: content.implicitHeight + padding * 2
    radius: Appearance.rounding.small
    color: pressed ? ColorUtils.stateLayer(containerColor, contentColor, Appearance.stateLayer.pressed)
        : hovered ? ColorUtils.stateLayer(containerColor, contentColor, Appearance.stateLayer.hover)
        : containerColor
    border.width: variant === "outlined" ? Appearance.sizes.m3OutlineWidth : 0
    border.color: Appearance.colors.colOutlineVariant

    Behavior on color {
        animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
    }

    StyledRectangularShadow {
        target: root
        visible: root.variant === "elevated"
        z: -1
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        enabled: root.interactive
        hoverEnabled: root.interactive
        cursorShape: root.interactive ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.clicked()
    }

    ColumnLayout {
        id: content
        anchors.fill: parent
        anchors.margins: root.padding
        spacing: Appearance.spacing.s
    }
}
