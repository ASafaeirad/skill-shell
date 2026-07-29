import Qt5Compat.GraphicalEffects
import QtQuick
import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.waffle.looks
import qs.services
import qs.services.network

StyledIndeterminateProgressBar {
    id: progressBar

    implicitHeight: 3
    background: null
    layer.enabled: true

    layer.effect: OpacityMask {

        maskSource: Rectangle {
            width: progressBar.width
            height: progressBar.height
            radius: progressBar.height / 2
        }

    }

}
