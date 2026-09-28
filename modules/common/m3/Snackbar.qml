import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

/**
 * Material 3 snackbar: brief feedback with an optional action.
 * https://m3.material.io/components/snackbar
 *
 *   M3.Snackbar { text: "Archived"; actionText: "Undo"; onActionClicked: undo() }
 *
 * variant: "single-line" (default) | "two-line". The two-line variant adds
 * supportingText. leadingIcon and progress support an in-place undo countdown.
 */
Rectangle {
    id: root

    property string variant: "single-line"
    property string text: ""
    property string supportingText: ""
    property string leadingIcon: ""
    property string actionText: ""
    property string actionTooltip: ""
    property real progress: -1
    signal actionClicked()

    implicitHeight: variant === "two-line" ? Appearance.sizes.m3SnackbarTwoLineHeight
                                           : Appearance.sizes.m3SnackbarSingleLineHeight
    implicitWidth: Appearance.spacing.xxl * 10
    radius: Appearance.rounding.verysmall
    color: Appearance.m3colors.m3inverseSurface
    clip: true

    MouseArea { anchors.fill: parent; hoverEnabled: true }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Appearance.spacing.lg
        anchors.rightMargin: Appearance.spacing.s
        spacing: Appearance.spacing.m

        MaterialSymbol {
            visible: root.leadingIcon.length > 0
            Layout.alignment: Qt.AlignVCenter
            text: root.leadingIcon
            iconSize: Appearance.font.pixelSize.larger
            color: Appearance.m3colors.m3inverseOnSurface
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacing.xxs
            StyledText {
                Layout.fillWidth: true
                text: root.text
                font.pixelSize: Appearance.font.pixelSize.smallie
                color: Appearance.m3colors.m3inverseOnSurface
                elide: Text.ElideRight
            }
            StyledText {
                visible: root.variant === "two-line" && root.supportingText.length > 0
                Layout.fillWidth: true
                text: root.supportingText
                font.pixelSize: Appearance.font.pixelSize.smallest
                color: Appearance.m3colors.m3inverseOnSurface
                elide: Text.ElideRight
            }
        }
        RippleButton {
            id: action
            visible: root.actionText.length > 0
            Layout.alignment: Qt.AlignVCenter
            implicitHeight: Appearance.sizes.m3ButtonHeight
            implicitWidth: actionLabel.implicitWidth + Appearance.spacing.xl * 2
            buttonRadius: Appearance.rounding.full
            buttonRadiusPressed: Appearance.rounding.small
            colBackground: "transparent"
            colBackgroundHover: ColorUtils.stateLayer(root.color, Appearance.m3colors.m3inversePrimary,
                                                      Appearance.stateLayer.hover)
            colRipple: ColorUtils.applyAlpha(Appearance.m3colors.m3inversePrimary,
                                             Appearance.stateLayer.pressed * 2)
            onClicked: root.actionClicked()

            contentItem: StyledText {
                id: actionLabel
                text: root.actionText
                color: Appearance.m3colors.m3inversePrimary
                font.pixelSize: Appearance.font.pixelSize.smaller
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            Tooltip {
                text: root.actionTooltip
                extraVisibleCondition: root.actionTooltip.length > 0
            }
        }
    }

    Rectangle {
        visible: root.progress >= 0
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        width: parent.width * Math.max(0, Math.min(1, root.progress))
        height: Appearance.spacing.xxs
        color: Appearance.m3colors.m3inversePrimary
    }
}
