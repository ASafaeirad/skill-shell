import QtQuick
import Quickshell
import Quickshell.Wayland
import qs
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.services

FullscreenPolkitWindow {
    id: root

    contentComponent: Component {
        WPolkitContent {
        }

    }

}
