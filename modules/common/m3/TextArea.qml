import QtQuick
import QtQuick.Controls as Controls
import qs.modules.common
import qs.modules.common.functions

/**
 * Material 3 multiline text field.
 * https://m3.material.io/components/text-fields
 *
 *   M3.TextArea { variant: "filled"; placeholderText: "Notes" }
 *
 * variant: "filled" (default) | "outlined"
 * surface: false embeds the editor in an existing surface, without a container or indicator.
 * Keeps the Controls.TextArea API, including selection, cursor geometry and ScrollView support.
 */
Controls.TextArea {
    id: root

    property string variant: "filled"
    property bool surface: true
    property bool error: false

    readonly property color contentColor: enabled ? Appearance.m3colors.m3onSurface
        : ColorUtils.applyAlpha(Appearance.m3colors.m3onSurface, Appearance.stateLayer.disabledContent)
    readonly property color indicatorColor: !enabled ? ColorUtils.applyAlpha(Appearance.m3colors.m3onSurface, Appearance.stateLayer.disabledContent)
        : error ? Appearance.m3colors.m3error
        : activeFocus ? Appearance.m3colors.m3primary
        : hovered ? Appearance.m3colors.m3onSurface : Appearance.m3colors.m3outline

    renderType: surface ? Text.QtRendering : Text.NativeRendering
    color: contentColor
    selectedTextColor: Appearance.m3colors.m3onSecondaryContainer
    selectionColor: Appearance.colors.colSecondaryContainer
    placeholderTextColor: enabled ? Appearance.m3colors.m3onSurfaceVariant : contentColor
    font {
        family: Appearance.font.family.main
        pixelSize: Appearance.font.pixelSize.small
        hintingPreference: Font.PreferFullHinting
        variableAxes: Appearance.font.variableAxes.main
    }
    wrapMode: TextEdit.Wrap
    padding: surface ? Appearance.spacing.m : Appearance.sizes.m3TextAreaEditorPadding

    background: Rectangle {
        visible: root.surface
        implicitHeight: root.surface ? Appearance.sizes.m3TextAreaMinHeight : 0
        radius: root.variant === "outlined" ? Appearance.sizes.m3TextAreaRadius : 0
        topLeftRadius: Appearance.sizes.m3TextAreaRadius
        topRightRadius: Appearance.sizes.m3TextAreaRadius
        color: root.variant === "outlined" ? "transparent"
            : !root.enabled ? ColorUtils.applyAlpha(Appearance.m3colors.m3onSurface, Appearance.stateLayer.disabledContainer)
            : ColorUtils.stateLayer(Appearance.m3colors.m3surfaceContainerHighest, root.contentColor,
                root.hovered ? Appearance.stateLayer.hover : 0)
        border.width: root.variant === "outlined" ? (root.activeFocus ? Appearance.sizes.m3TextAreaFocusIndicatorWidth : Appearance.sizes.m3OutlineWidth) : 0
        border.color: root.indicatorColor

        Rectangle {
            visible: root.variant === "filled"
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: root.activeFocus ? Appearance.sizes.m3TextAreaFocusIndicatorWidth : Appearance.sizes.m3OutlineWidth
            color: root.indicatorColor
            Behavior on color {
                animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
            }
        }
    }
}
