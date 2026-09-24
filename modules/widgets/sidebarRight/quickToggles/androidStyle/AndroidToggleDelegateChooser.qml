import QtQuick
import qs.modules.common.models.quickToggles

AndroidQuickToggleButton {
    id: root

    required property int index
    required property var modelData
    required property int startingIndex

    signal openAudioOutputDialog()
    signal openAudioInputDialog()
    signal openBluetoothDialog()
    signal openNightLightDialog()
    signal openWifiDialog()

    buttonIndex: root.startingIndex >= 0 ? (root.startingIndex + index) : -1
    buttonData: modelData
    expandedSize: (modelData?.size ?? 1) > 1
    cellSpacing: root.spacing
    cellSize: modelData?.size ?? 1

    toggleModel: modelLoader.item

    Loader {
        id: modelLoader
        sourceComponent: root.modelMap[root.modelData?.type] ?? null
    }

    readonly property var modelMap: ({
        "audio": audioComp,
        "bluetooth": bluetoothComp,
        "colorPicker": colorPickerComp,
        "darkMode": darkModeComp,
        "easyEffects": easyEffectsComp,
        "gameMode": gameModeComp,
        "idleInhibitor": idleInhibitorComp,
        "mic": micComp,
        "network": networkComp,
        "nightLight": nightLightComp,
        "notifications": notificationsComp,
        "powerProfile": powerProfileComp,
        "screenSnip": screenSnipComp
    })

    Component { id: audioComp; AudioToggle {} }
    Component { id: bluetoothComp; BluetoothToggle {} }
    Component { id: colorPickerComp; ColorPickerToggle {} }
    Component { id: darkModeComp; DarkModeToggle {} }
    Component { id: easyEffectsComp; EasyEffectsToggle {} }
    Component { id: gameModeComp; GameModeToggle {} }
    Component { id: idleInhibitorComp; IdleInhibitorToggle {} }
    Component { id: micComp; MicToggle {} }
    Component { id: networkComp; NetworkToggle {} }
    Component { id: nightLightComp; NightLightToggle {} }
    Component { id: notificationsComp; NotificationToggle {} }
    Component { id: powerProfileComp; PowerProfilesToggle {} }
    Component { id: screenSnipComp; ScreenSnipToggle {} }

    onOpenMenu: {
        switch (root.modelData?.type) {
        case "audio":
            root.openAudioOutputDialog();
            break;
        case "bluetooth":
            root.openBluetoothDialog();
            break;
        case "mic":
            root.openAudioInputDialog();
            break;
        case "network":
            root.openWifiDialog();
            break;
        case "nightLight":
            root.openNightLightDialog();
            break;
        }
    }
}
