import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.modules.widgets.onScreenDisplay
import qs.services

OsdValueIndicator {
    id: rotateIcon

    icon: "wb_twilight"
    name: "Gamma"
    from: Hyprsunset.gammaLowerLimit / 100
    value: Hyprsunset.gamma / 100 ?? 0.5
}
