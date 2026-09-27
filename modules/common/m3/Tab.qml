import qs.modules.common.widgets

/**
 * Material 3 secondary tab with an optional leading icon.
 * https://m3.material.io/components/tabs
 *
 *   M3.Tab { text: "Stopwatch"; materialIcon: "timer" }
 */
SecondaryTabButton {
    property alias materialIcon: root.buttonIcon
    id: root
}
