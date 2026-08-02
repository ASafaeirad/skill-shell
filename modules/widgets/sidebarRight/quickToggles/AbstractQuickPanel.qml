import QtQuick
import qs.modules.common

Rectangle {
    id: root

    signal openAudioOutputDialog()
    signal openAudioInputDialog()
    signal openBluetoothDialog()
    signal openNightLightDialog()
    signal openWifiDialog()

    radius: Appearance.rounding.normal
    color: Appearance.colors.colLayer1
}
