import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

StyledText {
    Layout.fillWidth: true
    style: Text.Raised
    styleColor: Appearance.colors.colShadow
    animateChange: Config.options.background.widgets.clock.digital.animateChange

    font {
        family: Appearance.font.family.expressive
        pixelSize: 20
        weight: 350
        // Set empty to prevent conflicts, not meaningless
        styleName: ""
        variableAxes: ({
        })
    }

}
