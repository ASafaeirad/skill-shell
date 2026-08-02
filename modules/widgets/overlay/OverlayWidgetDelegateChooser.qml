pragma ComponentBehavior: Bound
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import qs.modules.widgets.overlay.volumeMixer
import qs.modules.widgets.overlay.floatingImage
import qs.modules.widgets.overlay.fpsLimiter
import qs.modules.widgets.overlay.recorder
import qs.modules.widgets.overlay.resources
import qs.modules.widgets.overlay.notes

DelegateChooser {
    id: root
    role: "identifier"

    DelegateChoice { roleValue: "floatingImage"; FloatingImage {} }
    DelegateChoice { roleValue: "fpsLimiter"; FpsLimiter {} }
    DelegateChoice { roleValue: "recorder"; Recorder {} }
    DelegateChoice { roleValue: "resources"; Resources {} }
    DelegateChoice { roleValue: "notes"; Notes {} }
    DelegateChoice { roleValue: "volumeMixer"; VolumeMixer {} }
}
