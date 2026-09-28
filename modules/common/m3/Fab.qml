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
 * expanded + buttonText: the extended FAB. See FloatingActionButton in
 *   qs.modules.common.widgets for the rest of the API.
 */
FloatingActionButton {
    id: root

    property string variant: "primary"
    property string size: "regular"
    property bool elevated: false
    property string tooltip: ""

    baseSize: size === "toolbar" ? Appearance.sizes.m3ToolbarFabSize : Appearance.sizes.m3FabSize
    colBackground: variant === "tertiary" ? Appearance.colors.colTertiaryContainer
        : variant === "secondary" ? Appearance.colors.colSecondaryContainer
        : Appearance.colors.colPrimaryContainer
    colBackgroundHover: variant === "tertiary" ? Appearance.colors.colTertiaryContainerHover
        : variant === "secondary" ? Appearance.colors.colSecondaryContainerHover
        : Appearance.colors.colPrimaryContainerHover
    colRipple: variant === "tertiary" ? Appearance.colors.colTertiaryContainerActive
        : variant === "secondary" ? Appearance.colors.colSecondaryContainerActive
        : Appearance.colors.colPrimaryContainerActive
    colOnBackground: variant === "tertiary" ? Appearance.colors.colOnTertiaryContainer
        : variant === "secondary" ? Appearance.colors.colOnSecondaryContainer
        : Appearance.colors.colOnPrimaryContainer

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
