import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

Rectangle {
    id: root

    property string text: "Status"
    property string icon: ""
    property string tone: "neutral" // neutral, primary, success, error
    property bool outlined: false

    readonly property color toneColor: tone === "success" ? Appearance.m3colors.m3success
        : tone === "error" ? Appearance.m3colors.m3error
        : tone === "primary" ? Appearance.m3colors.m3primary
        : Appearance.m3colors.m3onSurfaceVariant
    readonly property color containerColor: tone === "success" ? Appearance.m3colors.m3successContainer
        : tone === "error" ? Appearance.m3colors.m3errorContainer
        : tone === "primary" ? Appearance.m3colors.m3primaryContainer
        : Appearance.m3colors.m3surfaceContainerHigh
    readonly property color labelColor: outlined ? toneColor
        : tone === "success" ? Appearance.m3colors.m3onSuccessContainer
        : tone === "error" ? Appearance.m3colors.m3onErrorContainer
        : tone === "primary" ? Appearance.m3colors.m3onPrimaryContainer
        : Appearance.m3colors.m3onSurfaceVariant

    implicitWidth: content.implicitWidth + Appearance.spacing.m * 2
    implicitHeight: content.implicitHeight + Appearance.spacing.xs * 2
    radius: Appearance.rounding.full
    color: outlined ? "transparent" : containerColor
    border.width: outlined ? 1 : 0
    border.color: toneColor

    RowLayout {
        id: content
        anchors.centerIn: parent
        spacing: Appearance.spacing.xs

        MaterialSymbol {
            visible: root.icon.length > 0
            text: root.icon
            iconSize: Appearance.font.pixelSize.small
            color: root.labelColor
        }

        StyledText {
            text: root.text
            color: root.labelColor
            font.pixelSize: Appearance.font.pixelSize.smallie
        }
    }
}
