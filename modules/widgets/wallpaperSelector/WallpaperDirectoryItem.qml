import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.m3 as M3
import qs.modules.common.widgets
import qs.services

Item {
    id: root

    required property var fileModelData
    property bool isDirectory: fileModelData.fileIsDir
    property bool useThumbnail: Images.isValidImageByName(fileModelData.fileName)
    property bool current: false
    property bool applied: false

    signal activated()
    signal entered()

    M3.Card {
        id: tile
        anchors.fill: parent
        anchors.margins: Appearance.sizes.wallpaperSelectorItemMargins
        variant: "filled"
        interactive: true
        padding: Appearance.sizes.wallpaperSelectorItemPadding
        spacing: Appearance.spacing.xs
        selected: root.current || root.applied
        selectedVariant: root.current ? "filled" : "tonal"
        onClicked: root.activated()

        onHoveredChanged: if (hovered) root.entered()

        ColumnLayout {
            id: wallpaperItemColumnLayout

            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Appearance.spacing.xs

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
                Layout.leftMargin: Appearance.spacing.s
                Layout.rightMargin: Appearance.spacing.s
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                font.pixelSize: Appearance.font.pixelSize.smaller
                text: fileModelData.fileName
                color: tile.contentColor

                Behavior on color {
                    animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                }

            }

        }

    }
}
