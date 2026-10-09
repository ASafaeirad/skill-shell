import qs.modules.common.m3 as M3

/**
 * Legacy name for M3.Slider, implemented in modules/common/m3/Slider.qml.
 * Kept so existing callers keep working; use M3.Slider in new code.
 */
M3.Slider {
    // Callers still write StyledSlider.Configuration.S; same values as M3.Slider's enum.
    enum Configuration {
        Wavy = 4,
        XS = 12,
        S = 18,
        M = 30,
        L = 42,
        XL = 72
    }
}
