import QtQuick
import qs.modules.common.models.quickToggles as QuickToggleModels

QuickToggleButton {
    toggleModel: QuickToggleModels.CameraToggle {}
    visible: true
    enabled: toggleModel.available
}
