import qs.modules.common
import qs.modules.common.widgets

/** Animated Material 3 dialog surface for M3.DialogOverlay. */
OverlayDialogCard {
    // Use for larger shell dialogs whose content needs a clipped, outlined surface.
    property bool outlinedSurface: false
    surfaceColor: outlinedSurface ? Appearance.colors.colBackgroundSurfaceContainer
                                  : Appearance.colors.colBackgroundSurfaceContainerHigh
    surface.radius: outlinedSurface ? Appearance.rounding.windowRounding : Appearance.rounding.large
    surface.border.color: Appearance.colors.colLayer0Border
    surface.border.width: outlinedSurface ? Appearance.spacing.xxs / 2 : 0
    surface.clip: outlinedSurface
}
