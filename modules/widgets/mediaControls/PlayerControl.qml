pragma ComponentBehavior: Bound
import qs
import qs.modules.common
import qs.modules.common.models
import qs.modules.common.widgets
import qs.modules.common.m3 as M3
import qs.services
import qs.modules.common.functions
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

Item { // Player instance
    id: root
    required property MprisPlayer player
    property var artUrl: player?.trackArtUrl
    property string artDownloadLocation: Directories.coverArt
    property string artFileName: Qt.md5(artUrl)
    property string artFilePath: `${artDownloadLocation}/${artFileName}`
    property bool downloaded: false
    property list<real> visualizerPoints: []
    property real maxVisualizerValue: 1000 // Max value in the data points
    property int visualizerSmoothing: 2 // Number of points to average for smoothing
    property real radius

    property string displayedArtFilePath: root.downloaded ? Qt.resolvedUrl(artFilePath) : ""

    Timer { // Force update for revision
        running: root.player?.playbackState == MprisPlaybackState.Playing
        interval: ResourceUsage.updateInterval
        repeat: true
        onTriggered: {
            root.player.positionChanged()
        }
    }

    onArtFilePathChanged: {
        if (root.artUrl.length == 0) {
            return;
        }

        // Binding does not work in Process
        coverArtDownloader.targetFile = root.artUrl
        coverArtDownloader.artFilePath = root.artFilePath
        // Download
        root.downloaded = false
        coverArtDownloader.running = true
    }

    Process { // Cover art downloader
        id: coverArtDownloader
        property string targetFile: root.artUrl
        property string artFilePath: root.artFilePath
        command: [ "bash", "-c", `[ -f ${artFilePath} ] || curl -4 -sSL '${targetFile}' -o '${artFilePath}'` ]
        onExited: (exitCode, exitStatus) => {
            root.downloaded = true
        }
    }

    StyledRectangularShadow {
        target: background
    }
    Rectangle { // Background
        id: background
        anchors.fill: parent
        anchors.margins: Appearance.sizes.elevationMargin
        color: Appearance.colors.colLayer0
        radius: root.radius

        layer.enabled: true
        layer.effect: OpacityMask {
            maskSource: Rectangle {
                width: background.width
                height: background.height
                radius: background.radius
            }
        }

        StyledImage {
            id: blurredArt
            anchors.fill: parent
            source: root.displayedArtFilePath
            fillMode: Image.PreserveAspectCrop
            cache: false
            antialiasing: true
            asynchronous: true

            layer.enabled: true
            layer.effect: StyledBlurEffect {
                source: blurredArt
            }

            Rectangle {
                anchors.fill: parent
                color: ColorUtils.transparentize(Appearance.colors.colLayer0, Appearance.stateLayer.mediaPlayerArtScrimTransparency)
                radius: root.radius
            }
        }

        WaveVisualizer {
            id: visualizerCanvas
            anchors.fill: parent
            live: root.player?.isPlaying
            points: root.visualizerPoints
            maxVisualizerValue: root.maxVisualizerValue
            smoothing: root.visualizerSmoothing
            color: Appearance.colors.colPrimary
        }

        MouseArea {
            id: rowClickArea
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            onClicked: {
                MprisController.focusPlayer(root.player);
                GlobalStates.mediaControls?.close();
            }
        }

        Rectangle {
            id: hoverHighlight
            anchors.fill: parent
            radius: root.radius
            color: Appearance.colors.colOnLayer0
            opacity: rowClickArea.containsMouse ? Appearance.stateLayer.hover : 0
            Behavior on opacity {
                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
            }
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: Appearance.sizes.mediaPlayerPadding
            spacing: Appearance.sizes.mediaPlayerGap

            Rectangle { // Art background
                id: artBackground
                Layout.fillHeight: true
                implicitWidth: height
                radius: Appearance.rounding.verysmall
                color: ColorUtils.transparentize(Appearance.colors.colLayer1, Appearance.stateLayer.mediaPlayerArtBackgroundTransparency)

                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: Rectangle {
                        width: artBackground.width
                        height: artBackground.height
                        radius: artBackground.radius
                    }
                }

                StyledImage { // Art image
                    id: mediaArt
                    property int size: parent.height
                    anchors.fill: parent

                    source: root.displayedArtFilePath
                    fillMode: Image.PreserveAspectCrop
                    cache: false
                    antialiasing: true

                    width: size
                    height: size
                }
            }

            ColumnLayout { // Info & controls
                Layout.fillHeight: true
                spacing: Appearance.spacing.xxs

                StyledText {
                    id: trackTitle
                    Layout.fillWidth: true
                    font.pixelSize: Appearance.font.pixelSize.large
                    color: Appearance.colors.colOnLayer0
                    elide: Text.ElideRight
                    text: StringUtils.cleanMusicTitle(root.player?.trackTitle) || "Untitled"
                    animateChange: true
                    animationDistanceX: Appearance.sizes.mediaPlayerTextAnimationDistance
                    animationDistanceY: 0
                }
                StyledText {
                    id: trackArtist
                    Layout.fillWidth: true
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colSubtext
                    elide: Text.ElideRight
                    text: root.player?.trackArtist
                    animateChange: true
                    animationDistanceX: Appearance.sizes.mediaPlayerTextAnimationDistance
                    animationDistanceY: 0
                }
                Item { Layout.fillHeight: true }
                Item {
                    Layout.fillWidth: true
                    implicitHeight: trackTime.implicitHeight + sliderRow.implicitHeight

                    StyledText {
                        id: trackTime
                        anchors.bottom: sliderRow.top
                        anchors.bottomMargin: Appearance.spacing.xs
                        anchors.left: parent.left
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colSubtext
                        elide: Text.ElideRight
                        text: `${StringUtils.friendlyTimeForSeconds(root.player?.position)} / ${StringUtils.friendlyTimeForSeconds(root.player?.length)}`
                    }
                    RowLayout {
                        id: sliderRow
                        anchors {
                            bottom: parent.bottom
                            left: parent.left
                            right: parent.right
                        }
                        M3.IconButton {
                            size: "xsmall"
                            materialIcon: "skip_previous"
                            tooltip: "Previous track"
                            onClicked: root.player?.previous()
                        }
                        Item {
                            id: progressBarContainer
                            Layout.fillWidth: true
                            implicitHeight: Math.max(sliderLoader.implicitHeight, progressBarLoader.implicitHeight)

                            Loader {
                                id: sliderLoader
                                anchors.fill: parent
                                active: root.player?.canSeek ?? false
                                sourceComponent: M3.Slider {
                                    configuration: M3.Slider.Configuration.Wavy
                                    value: root.player?.length > 0 ? root.player.position / root.player.length : 0
                                    onMoved: {
                                        root.player.position = value * root.player.length;
                                    }
                                }
                            }

                            Loader {
                                id: progressBarLoader
                                anchors {
                                    verticalCenter: parent.verticalCenter
                                    left: parent.left
                                    right: parent.right
                                }
                                active: !(root.player?.canSeek ?? false)
                                sourceComponent: M3.LinearProgressIndicator {
                                    wavy: root.player?.isPlaying
                                    value: root.player?.length > 0 ? root.player.position / root.player.length : 0
                                }
                            }


                        }
                        M3.IconButton {
                            size: "xsmall"
                            materialIcon: "skip_next"
                            tooltip: "Next track"
                            onClicked: root.player?.next()
                        }
                    }

                    M3.IconButton {
                        id: playPauseButton
                        anchors.right: parent.right
                        anchors.bottom: sliderRow.top
                        anchors.bottomMargin: Appearance.spacing.xs
                        size: "medium"
                        variant: root.player?.isPlaying ? "filled" : "tonal"
                        shape: root.player?.isPlaying ? "square" : "round"
                        materialIcon: root.player?.isPlaying ? "pause" : "play_arrow"
                        iconFilled: true
                        tooltip: root.player?.isPlaying ? "Pause" : "Play"
                        onClicked: root.player?.togglePlaying()
                    }
                }
            }
        }
    }
}
