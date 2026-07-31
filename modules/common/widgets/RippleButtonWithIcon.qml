import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

RippleButton {
    id: buttonWithIconRoot

    property string nerdIcon
    property string materialIcon
    property bool materialIconFill: true
    property string mainText: "Button text"
    property Component mainContentComponent
    property bool primary: false
    readonly property color colContent: primary ? Appearance.colors.colOnPrimary : Appearance.colors.colOnSecondaryContainer

    implicitHeight: 35
    horizontalPadding: 10
    buttonRadius: Appearance.rounding.small
    colBackground: primary ? Appearance.colors.colPrimary : Appearance.colors.colLayer2
    colBackgroundHover: primary ? Appearance.colors.colPrimaryHover : Appearance.colors.colLayer1Hover
    colRipple: primary ? Appearance.colors.colPrimaryActive : Appearance.colors.colLayer1Active

    mainContentComponent: Component {
        StyledText {
            visible: text !== ""
            text: buttonWithIconRoot.mainText
            font.pixelSize: Appearance.font.pixelSize.small
            color: buttonWithIconRoot.colContent
        }

    }

    contentItem: RowLayout {
        Item {
            Layout.fillWidth: false
            implicitWidth: Math.max(materialIconLoader.implicitWidth, nerdIconLoader.implicitWidth)

            Loader {
                id: materialIconLoader

                anchors.centerIn: parent
                active: !nerdIcon

                sourceComponent: MaterialSymbol {
                    text: buttonWithIconRoot.materialIcon
                    iconSize: Appearance.font.pixelSize.larger
                    color: buttonWithIconRoot.colContent
                    fill: buttonWithIconRoot.materialIconFill ? 1 : 0
                }

            }

            Loader {
                id: nerdIconLoader

                anchors.centerIn: parent
                active: nerdIcon

                sourceComponent: StyledText {
                    text: buttonWithIconRoot.nerdIcon
                    font.pixelSize: Appearance.font.pixelSize.larger
                    font.family: Appearance.font.family.iconNerd
                    color: buttonWithIconRoot.colContent
                }

            }

        }

        Loader {
            Layout.fillWidth: true
            sourceComponent: buttonWithIconRoot.mainContentComponent
            Layout.alignment: Qt.AlignVCenter
        }

    }

}
