pragma ComponentBehavior: Bound

import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

/**
 * The media grabber card: one view per YtDlp.view state (idle, fetching,
 * ready, downloading, done, error) under a shared header.
 */
OverlayDialogCard {
    id: root

    signal closeRequested()

    readonly property string view: YtDlp.view
    readonly property bool hasUrl: YtDlp.url.trim().length > 0
    readonly property real sectionPadding: Appearance.spacing.lg
    readonly property real buttonHeight: Appearance.spacing.xxl + Appearance.spacing.s
    readonly property real smallButtonHeight: Appearance.spacing.xxl + Appearance.spacing.xxs * 2

    function focusView(): void {
        if (root.view === "idle")
            urlInput.forceActiveFocus();
        else
            root.forceActiveFocus();
    }

    Component.onCompleted: animateIn()
    onAboutToAnimateIn: root.focusView()
    onViewChanged: root.focusView()

    focus: true

    implicitWidth: Appearance.sizes.mediaGrabberWidth + 2 * Appearance.sizes.elevationMargin
    implicitHeight: 2 * Appearance.sizes.elevationMargin + contentColumn.implicitHeight
    surfaceColor: Appearance.colors.colBackgroundSurfaceContainer
    surface.radius: Appearance.rounding.normal
    surface.border.color: Appearance.colors.colLayer0Border
    surface.border.width: Appearance.spacing.xxs / 2
    surface.clip: true

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) {
            root.closeRequested();
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            if (root.view === "ready")
                YtDlp.download();
            else if (root.view === "error")
                YtDlp.retry();
        } else {
            event.accepted = false;
            return;
        }
        event.accepted = true;
    }

    Behavior on implicitHeight {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }

    // A rounded, full-width or content-width action: icon plus label.
    component PillButton: RippleButton {
        id: pill

        property string symbol: ""
        property string label: ""
        property color foreground: Appearance.colors.colOnLayer2
        property int labelSize: Appearance.font.pixelSize.smaller

        buttonRadius: Appearance.rounding.full
        colBackground: Appearance.colors.colSurfaceContainerHigh
        colBackgroundHover: Appearance.colors.colSurfaceContainerHighestHover
        implicitHeight: root.smallButtonHeight
        implicitWidth: pillContent.implicitWidth + Appearance.spacing.m * 2

        contentItem: Item {
            RowLayout {
                id: pillContent

                anchors.centerIn: parent
                spacing: Appearance.spacing.xs

                MaterialSymbol {
                    text: pill.symbol
                    iconSize: Appearance.font.pixelSize.normal
                    color: pill.foreground
                }
                StyledText {
                    text: pill.label
                    font.pixelSize: pill.labelSize
                    color: pill.foreground
                }
            }
        }
    }

    component PrimaryPillButton: PillButton {
        colBackground: Appearance.colors.colPrimary
        colBackgroundHover: Appearance.colors.colPrimaryHover
        colRipple: Appearance.colors.colPrimaryActive
        foreground: Appearance.colors.colOnPrimary
    }

    // A skeleton block with a highlight sweeping across it.
    component Shimmer: Rectangle {
        id: shimmer

        color: Appearance.colors.colSurfaceContainerHighest
        clip: true

        Rectangle {
            width: shimmer.width
            height: shimmer.height
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: "transparent" }
                GradientStop { position: 0.5; color: Appearance.colors.colSurfaceContainerHigh }
                GradientStop { position: 1; color: "transparent" }
            }

            NumberAnimation on x {
                running: shimmer.visible
                loops: Animation.Infinite
                from: -shimmer.width
                to: shimmer.width
                duration: Appearance.animation.elementMove.duration * 3
            }
        }
    }

    // The video thumbnail, or a play glyph while there is none.
    component Thumbnail: Rectangle {
        id: thumb

        property bool showDuration: false

        Layout.preferredWidth: Appearance.sizes.mediaGrabberThumbnailWidth
        Layout.preferredHeight: Appearance.sizes.mediaGrabberThumbnailWidth * 9 / 16
        radius: Appearance.rounding.small
        color: Appearance.colors.colSurfaceContainerHighest
        layer.enabled: true
        layer.effect: OpacityMask {
            maskSource: Rectangle {
                width: thumb.width
                height: thumb.height
                radius: thumb.radius
            }
        }

        MaterialSymbol {
            anchors.centerIn: parent
            visible: thumbImage.status !== Image.Ready
            text: "play_circle"
            iconSize: Appearance.font.pixelSize.hugeass
            color: Appearance.colors.colSubtext
        }

        StyledImage {
            id: thumbImage

            anchors.fill: parent
            source: YtDlp.thumbnail
            fillMode: Image.PreserveAspectCrop
        }

        Rectangle {
            visible: thumb.showDuration && YtDlp.duration.length > 0
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: Appearance.spacing.xs - Appearance.spacing.xxs
            implicitWidth: durationText.implicitWidth + Appearance.spacing.xs
            implicitHeight: durationText.implicitHeight + Appearance.spacing.xxs
            radius: Appearance.rounding.unsharpenmore
            color: ColorUtils.transparentize(Appearance.m3colors.m3surface, 0.25)

            StyledText {
                id: durationText

                anchors.centerIn: parent
                text: YtDlp.duration
                font.pixelSize: Appearance.font.pixelSize.smallest
                color: Appearance.m3colors.m3onSurface
            }
        }
    }

    // Thumbnail with the title and one line of detail beside it.
    component MediaSummary: RowLayout {
        id: summary

        property bool showDuration: false
        default property alias detail: detailSlot.data

        Layout.fillWidth: true
        spacing: Appearance.spacing.m

        Thumbnail {
            showDuration: summary.showDuration
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: Appearance.spacing.xs

            StyledText {
                Layout.fillWidth: true
                text: YtDlp.title
                font.pixelSize: Appearance.font.pixelSize.smallie
                color: Appearance.colors.colOnSurface
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
            }
            RowLayout {
                id: detailSlot

                spacing: Appearance.spacing.xs
            }
        }
    }

    component SectionLabel: StyledText {
        font.pixelSize: Appearance.font.pixelSize.smallest
        font.letterSpacing: Appearance.font.pixelSize.smallest * 0.06
        color: Appearance.colors.colSubtext
    }

    ColumnLayout {
        id: contentColumn

        anchors.fill: parent
        anchors.margins: Appearance.sizes.elevationMargin
        spacing: 0

        // Header
        RowLayout {
            Layout.fillWidth: true
            Layout.margins: Appearance.spacing.m
            spacing: Appearance.spacing.s

            MaterialSymbol {
                text: "download"
                iconSize: Appearance.font.pixelSize.large
                color: Appearance.colors.colPrimary
            }
            StyledText {
                Layout.fillWidth: true
                text: "Media Grabber"
                font.pixelSize: Appearance.font.pixelSize.small
                color: Appearance.colors.colOnSurface
            }
            SectionLabel {
                text: "YT-DLP"
            }
        }
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: Appearance.spacing.xxs / 2
            color: Appearance.colors.colLayer0Border
        }

        // Idle: link entry
        ColumnLayout {
            visible: root.view === "idle"
            Layout.fillWidth: true
            Layout.margins: root.sectionPadding
            Layout.topMargin: Appearance.spacing.lg + Appearance.spacing.xxs
            spacing: Appearance.spacing.m

            StyledText {
                Layout.fillWidth: true
                text: "Paste a link from YouTube, Instagram or X to fetch and download it."
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colSubtext
                wrapMode: Text.Wrap
                lineHeight: 1.2
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: urlInput.implicitHeight + Appearance.spacing.m * 2
                radius: Appearance.rounding.small
                color: Appearance.colors.colSurfaceContainerHigh
                border.width: Appearance.spacing.xxs / 2
                border.color: urlInput.activeFocus ? Appearance.colors.colPrimary : Appearance.colors.colOutlineVariant

                StyledTextInput {
                    id: urlInput

                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.right: pasteButton.left
                    anchors.leftMargin: Appearance.spacing.m
                    anchors.rightMargin: Appearance.spacing.xs
                    clip: true
                    focus: true
                    color: Appearance.colors.colOnSurface
                    font.pixelSize: Appearance.font.pixelSize.small
                    text: YtDlp.url
                    onTextEdited: YtDlp.url = text
                    onAccepted: YtDlp.fetch()

                    StyledText {
                        anchors.fill: parent
                        visible: urlInput.text.length === 0
                        text: "https://…"
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colSubtext
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                RippleButton {
                    id: pasteButton

                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: parent.right
                    anchors.rightMargin: Appearance.spacing.s
                    implicitWidth: Appearance.spacing.xxl - Appearance.spacing.xxs
                    implicitHeight: implicitWidth
                    buttonRadius: Appearance.rounding.full
                    colBackgroundHover: Appearance.colors.colLayer3Hover
                    onClicked: YtDlp.pasteUrl()

                    contentItem: MaterialSymbol {
                        horizontalAlignment: Text.AlignHCenter
                        text: "content_paste"
                        iconSize: Appearance.font.pixelSize.large
                        color: pasteButton.hovered ? Appearance.colors.colOnLayer2 : Appearance.colors.colSubtext
                    }
                }
            }

            PillButton {
                Layout.fillWidth: true
                implicitHeight: root.buttonHeight
                symbol: "search"
                label: "Fetch info"
                labelSize: Appearance.font.pixelSize.smallie
                colBackground: root.hasUrl ? Appearance.colors.colPrimary : Appearance.colors.colSurfaceContainerHigh
                colBackgroundHover: root.hasUrl ? Appearance.colors.colPrimaryHover : Appearance.colors.colSurfaceContainerHigh
                colRipple: root.hasUrl ? Appearance.colors.colPrimaryActive : "transparent"
                foreground: root.hasUrl ? Appearance.colors.colOnPrimary : Appearance.colors.colSubtext
                pointingHandCursor: root.hasUrl
                onClicked: YtDlp.fetch()
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: Appearance.spacing.xxs
                spacing: Appearance.spacing.xs

                Repeater {
                    model: ["smart_display", "photo_camera", "tag"]
                    delegate: MaterialSymbol {
                        required property string modelData
                        text: modelData
                        iconSize: Appearance.font.pixelSize.smallie
                        color: Appearance.colors.colSubtext
                    }
                }
                SectionLabel {
                    Layout.leftMargin: Appearance.spacing.xxs
                    text: "YouTube · Instagram · X"
                    font.letterSpacing: 0
                }
            }
        }

        // Fetching: metadata skeleton
        ColumnLayout {
            visible: root.view === "fetching"
            Layout.fillWidth: true
            Layout.margins: root.sectionPadding
            spacing: Appearance.spacing.m

            RowLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacing.m

                Shimmer {
                    Layout.preferredWidth: Appearance.sizes.mediaGrabberThumbnailWidth
                    Layout.preferredHeight: Appearance.sizes.mediaGrabberThumbnailWidth * 9 / 16
                    radius: Appearance.rounding.small
                }
                Column {
                    id: skeletonLines

                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignTop
                    Layout.topMargin: Appearance.spacing.xs - Appearance.spacing.xxs
                    spacing: Appearance.spacing.s

                    Shimmer {
                        width: skeletonLines.width * 0.9
                        height: Appearance.spacing.m
                        radius: Appearance.rounding.full
                    }
                    Shimmer {
                        width: skeletonLines.width * 0.55
                        height: Appearance.spacing.m
                        radius: Appearance.rounding.full
                    }
                    Item {
                        width: 1
                        height: Appearance.spacing.xxs
                    }
                    Shimmer {
                        width: skeletonLines.width * 0.35
                        height: Appearance.spacing.s
                        radius: Appearance.rounding.full
                    }
                }
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: Appearance.spacing.s
                spacing: Appearance.spacing.s

                MaterialSymbol {
                    text: "progress_activity"
                    iconSize: Appearance.font.pixelSize.large
                    color: Appearance.colors.colPrimary

                    RotationAnimation on rotation {
                        running: root.view === "fetching"
                        loops: Animation.Infinite
                        from: 0
                        to: 360
                        duration: Appearance.animation.elementMove.duration * 2
                    }
                }
                StyledText {
                    text: "Fetching video info…"
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colSubtext
                }
            }
        }

        // Ready: pick a quality
        ColumnLayout {
            visible: root.view === "ready"
            Layout.fillWidth: true
            Layout.margins: root.sectionPadding
            spacing: Appearance.spacing.lg

            MediaSummary {
                showDuration: true

                MaterialSymbol {
                    text: YtDlp.platformIcon
                    iconSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colPrimary
                }
                SectionLabel {
                    text: YtDlp.platformLabel
                    font.letterSpacing: 0
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacing.s

                SectionLabel {
                    text: "QUALITY"
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: qualityRow.implicitHeight + Appearance.spacing.xxs * 2
                    radius: Appearance.rounding.normal
                    color: Appearance.colors.colLayer1

                    RowLayout {
                        id: qualityRow

                        anchors.fill: parent
                        anchors.margins: Appearance.spacing.xxs
                        spacing: Appearance.spacing.xxs

                        Repeater {
                            model: [
                                { key: "best", label: "Best" },
                                { key: "medium", label: "Medium" },
                                { key: "audio", label: "Audio only" }
                            ]
                            delegate: RippleButton {
                                id: qualityOption

                                required property var modelData
                                readonly property bool selected: YtDlp.quality === modelData.key

                                Layout.fillWidth: true
                                implicitHeight: root.smallButtonHeight
                                buttonRadius: Appearance.rounding.small
                                toggled: qualityOption.selected
                                colBackgroundHover: Appearance.colors.colLayer1Hover
                                onClicked: YtDlp.quality = modelData.key

                                contentItem: StyledText {
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    text: qualityOption.modelData.label
                                    font.pixelSize: Appearance.font.pixelSize.smaller
                                    color: qualityOption.selected ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer1
                                }
                            }
                        }
                    }
                }
            }

            PrimaryPillButton {
                Layout.fillWidth: true
                implicitHeight: root.buttonHeight
                symbol: YtDlp.quality === "audio" ? "audiotrack" : "download"
                label: YtDlp.quality === "audio" ? "Download audio" : "Download video"
                labelSize: Appearance.font.pixelSize.smallie
                onClicked: YtDlp.download()
            }

            MouseArea {
                id: cancelLink

                Layout.alignment: Qt.AlignHCenter
                implicitWidth: cancelRow.implicitWidth
                implicitHeight: cancelRow.implicitHeight
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: YtDlp.reset()

                RowLayout {
                    id: cancelRow

                    opacity: cancelLink.containsMouse ? 0.8 : 1
                    spacing: Appearance.spacing.xs

                    MaterialSymbol {
                        text: "close"
                        iconSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colSubtext
                    }
                    StyledText {
                        text: "Cancel"
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colSubtext
                    }
                }
            }
        }

        // Downloading: progress
        ColumnLayout {
            visible: root.view === "downloading"
            Layout.fillWidth: true
            Layout.margins: root.sectionPadding
            spacing: Appearance.spacing.lg

            MediaSummary {
                SectionLabel {
                    text: YtDlp.qualityLabel
                    font.letterSpacing: 0
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacing.s

                RowLayout {
                    Layout.fillWidth: true

                    StyledText {
                        Layout.fillWidth: true
                        // yt-dlp merges or converts once the streams are in.
                        text: YtDlp.progress >= 1 ? "Finishing…" : "Downloading…"
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colOnLayer1
                    }
                    StyledText {
                        text: `${Math.round(YtDlp.progress * 100)}%`
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        font.features: ({ "tnum": 1 })
                        color: Appearance.colors.colPrimary
                    }
                }

                RowLayout {
                    id: progressTrack

                    Layout.fillWidth: true
                    spacing: Appearance.spacing.xxs * 2

                    Rectangle {
                        Layout.preferredWidth: (progressTrack.width - progressTrack.spacing) * YtDlp.progress
                        visible: YtDlp.progress > 0
                        implicitHeight: Appearance.spacing.xxs * 2
                        radius: Appearance.rounding.full
                        color: Appearance.colors.colPrimary

                        Behavior on Layout.preferredWidth {
                            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                        }
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        visible: YtDlp.progress < 1
                        implicitHeight: Appearance.spacing.xxs * 2
                        radius: Appearance.rounding.full
                        color: Appearance.colors.colSurfaceContainerHighest
                    }
                }

                RowLayout {
                    Layout.fillWidth: true

                    SectionLabel {
                        Layout.fillWidth: true
                        text: YtDlp.speed
                        font.letterSpacing: 0
                    }
                    SectionLabel {
                        visible: YtDlp.eta.length > 0
                        text: `ETA ${YtDlp.eta}`
                        font.letterSpacing: 0
                    }
                }
            }

            PillButton {
                Layout.fillWidth: true
                symbol: "close"
                label: "Cancel"
                onClicked: YtDlp.cancelDownload()
            }
        }

        // Done
        ColumnLayout {
            visible: root.view === "done"
            Layout.fillWidth: true
            Layout.margins: Appearance.spacing.xl
            Layout.topMargin: Appearance.spacing.xxl
            spacing: Appearance.spacing.s

            MaterialSymbol {
                Layout.alignment: Qt.AlignHCenter
                text: "check_circle"
                iconSize: Appearance.font.pixelSize.hugeass
                color: Appearance.m3colors.m3success
            }
            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: "Saved"
                font.pixelSize: Appearance.font.pixelSize.small
                color: Appearance.colors.colOnSurface
            }
            StyledText {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: `${YtDlp.title} · ${YtDlp.qualityLabel}`
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colSubtext
                wrapMode: Text.Wrap
            }
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: Appearance.spacing.xs
                spacing: Appearance.spacing.s

                PrimaryPillButton {
                    visible: YtDlp.savedPath.length > 0
                    symbol: "folder_open"
                    label: "Show in folder"
                    onClicked: {
                        YtDlp.showInFolder();
                        root.closeRequested();
                    }
                }
                PillButton {
                    symbol: "add"
                    label: "New download"
                    onClicked: {
                        YtDlp.url = "";
                        YtDlp.reset();
                    }
                }
            }
        }

        // Error
        Rectangle {
            visible: root.view === "error"
            Layout.fillWidth: true
            implicitHeight: errorBanner.implicitHeight + Appearance.spacing.m * 2
            color: Appearance.colors.colErrorContainer

            RowLayout {
                id: errorBanner

                anchors.fill: parent
                anchors.margins: Appearance.spacing.m
                anchors.leftMargin: Appearance.spacing.lg
                anchors.rightMargin: Appearance.spacing.lg
                spacing: Appearance.spacing.s

                MaterialSymbol {
                    Layout.alignment: Qt.AlignTop
                    text: "error"
                    iconSize: Appearance.font.pixelSize.large
                    color: Appearance.colors.colOnErrorContainer
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Appearance.spacing.xxs

                    StyledText {
                        Layout.fillWidth: true
                        text: YtDlp.failedStep === "download" ? "Download failed" : "Couldn't fetch that link"
                        font.pixelSize: Appearance.font.pixelSize.smallie
                        color: Appearance.colors.colOnErrorContainer
                        wrapMode: Text.Wrap
                    }
                    StyledText {
                        Layout.fillWidth: true
                        text: YtDlp.errorMessage || "Unsupported URL, or the source removed the media."
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colOnErrorContainer
                        wrapMode: Text.Wrap
                    }
                }
            }
        }
        ColumnLayout {
            visible: root.view === "error"
            Layout.fillWidth: true
            Layout.margins: root.sectionPadding
            spacing: Appearance.spacing.m

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: failedUrl.implicitHeight + Appearance.spacing.s * 2
                radius: Appearance.rounding.small
                color: Appearance.colors.colSurfaceContainerHigh

                StyledText {
                    id: failedUrl

                    anchors.fill: parent
                    anchors.margins: Appearance.spacing.s
                    anchors.leftMargin: Appearance.spacing.m
                    anchors.rightMargin: Appearance.spacing.m
                    text: YtDlp.url
                    font.family: Appearance.font.family.monospace
                    font.pixelSize: Appearance.font.pixelSize.smallest
                    color: Appearance.colors.colSubtext
                    wrapMode: Text.WrapAnywhere
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacing.s

                PrimaryPillButton {
                    Layout.fillWidth: true
                    symbol: "refresh"
                    label: "Retry"
                    onClicked: YtDlp.retry()
                }
                PillButton {
                    Layout.fillWidth: true
                    symbol: "edit"
                    label: "Edit URL"
                    onClicked: YtDlp.reset()
                }
            }
        }
    }
}
