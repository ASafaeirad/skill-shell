import QtQuick
import Quickshell
import qs.modules.common
import qs.modules.common.models.quickToggles
import qs.modules.common.widgets
import qs.services

AndroidQuickToggleButton {
    id: root

    toggleModel: AntiFlashbangToggle {
    }

}
