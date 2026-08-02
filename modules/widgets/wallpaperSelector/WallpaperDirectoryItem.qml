import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.services

MouseArea {
    id: root

    required property var fileModelData
    property bool isDirectory: fileModelData.fileIsDir
    property bool useThumbnail: Images.isValidImageByName(fileModelData.fileName)
    property alias colBackground: background.color
    property alias colText: wallpaperItemName.color
    property alias radius: background.radius
    property alias margins: background.anchors.margins
    property alias padding: wallpaperItemColumnLayout.anchors.margins

    signal activated()

    margins: Appearance.sizes.wallpaperSelectorItemMargins
    padding: Appearance.sizes.wallpaperSelectorItemPadding
    hoverEnabled: true
    onClicked: root.activated()

    Rectangle {
        id: background

        anchors.fill: parent
        radius: Appearance.rounding.normal

        ColumnLayout {
            id: wallpaperItemColumnLayout

            anchors.fill: parent
            spacing: 4

            Item {
                id: wallpaperItemImageContainer

                Layout.fillHeight: true
                Layout.fillWidth: true

                Loader {
                    id: thumbnailShadowLoader

                    active: thumbnailImageLoader.active && thumbnailImageLoader.item.status === Image.Ready
                    anchors.fill: thumbnailImageLoader

                    sourceComponent: StyledRectangularShadow {
                        target: thumbnailImageLoader
                        anchors.fill: undefined
                        radius: Appearance.rounding.small
                    }

                }

                Loader {
                    id: thumbnailImageLoader

                    anchors.fill: parent
                    active: root.useThumbnail

                    sourceComponent: ThumbnailImage {
                        id: thumbnailImage

                        generateThumbnail: false
                        sourcePath: fileModelData.filePath
                        cache: false
                        fillMode: Image.PreserveAspectCrop
                        clip: true
                        layer.enabled: true

                        Connections {
                            function onThumbnailGenerated(directory) {
                                if (thumbnailImage.status !== Image.Error)
                                    return ;

                                if (FileUtils.parentDirectory(thumbnailImage.sourcePath) !== FileUtils.trimFileProtocol(directory))
                                    return ;

                                thumbnailImage.source = "";
                                thumbnailImage.source = thumbnailImage.thumbnailPath;
                            }

                            function onThumbnailGeneratedFile(filePath) {
                                if (thumbnailImage.status !== Image.Error)
                                    return ;

                                if (Qt.resolvedUrl(thumbnailImage.sourcePath) !== Qt.resolvedUrl(filePath))
                                    return ;

                                thumbnailImage.source = "";
                                thumbnailImage.source = thumbnailImage.thumbnailPath;
                            }

                            target: Wallpapers
                        }

                        layer.effect: OpacityMask {

                            maskSource: Rectangle {
                                width: wallpaperItemImageContainer.width
                                height: wallpaperItemImageContainer.height
                                radius: Appearance.rounding.small
                            }

                        }

                    }

                }

                Loader {
                    id: iconLoader

                    active: !root.useThumbnail
                    anchors.fill: parent

                    sourceComponent: DirectoryIcon {
                        fileModelData: root.fileModelData
                    }

                }

            }

            StyledText {
                id: wallpaperItemName

                Layout.fillWidth: true
                Layout.leftMargin: 10
                Layout.rightMargin: 10
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                font.pixelSize: Appearance.font.pixelSize.smaller
                text: fileModelData.fileName

                Behavior on color {
                    animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                }

            }

        }

        Behavior on color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }

    }

}
