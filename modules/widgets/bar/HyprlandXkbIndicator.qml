import QtQuick
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.services

Loader {
    id: root

    property color color: Appearance.colors.colOnSurfaceVariant

    function abbreviateLayoutCode(fullCode) {
        return fullCode.split(':').map((layout) => {
            const baseLayout = layout.split('-')[0];
            return StringUtils.toSmallCaps(baseLayout.slice(0, 4));
        }).join('\n');
    }

    active: HyprlandXkb.layoutCodes.length > 1
    visible: active

    sourceComponent: Item {
        implicitWidth: layoutCodeText.implicitWidth
        implicitHeight: layoutCodeText.implicitHeight

        StyledText {
            id: layoutCodeText

            anchors.centerIn: parent
            // Small-caps glyphs sit on the baseline with empty ascender space above,
            // so nudge up slightly for optical centering
            anchors.verticalCenterOffset: -1
            horizontalAlignment: Text.AlignHCenter
            text: abbreviateLayoutCode(HyprlandXkb.currentLayoutCode)
            font.pixelSize: text.includes("\n") ? Appearance.font.pixelSize.smallie : Appearance.font.pixelSize.small
            color: root.color
            animateChange: true
        }

    }

}
