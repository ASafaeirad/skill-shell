import QtQuick
import qs.modules.common

/**
 * Material 3 menu surface for actions and nested menus.
 * https://m3.material.io/components/menus
 *
 *   M3.Menu { M3.MenuItem { text: "Copy" } }
 *
 * Use the default filled surface with M3.MenuItem rows and M3.Divider groups.
 */
Rectangle {
    color: Appearance.m3colors.m3surfaceContainerHigh
    radius: Appearance.rounding.normal
    clip: true
}
