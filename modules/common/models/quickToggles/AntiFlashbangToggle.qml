import QtQuick
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.services

QuickToggleModel {
    name: HyprlandAntiFlashbangShader.enabled ? (HyprlandAntiFlashbangShader.weak ? "Anti-flash: Weak" : "Anti-flash: Strong") : "Anti-flashbang"
    tooltipText: `${"Anti-flashbang"}: ${HyprlandAntiFlashbangShader.enabled ? (HyprlandAntiFlashbangShader.weak ? "Weak" : "Strong") : "Off"}`
    icon: HyprlandAntiFlashbangShader.enabled ? (!HyprlandAntiFlashbangShader.weak ? "flash_off" : "sunny_snowing") : "flash_on"
    toggled: HyprlandAntiFlashbangShader.enabled
    mainAction: () => {
        HyprlandAntiFlashbangShader.cycle();
    }
    hasMenu: true
}
