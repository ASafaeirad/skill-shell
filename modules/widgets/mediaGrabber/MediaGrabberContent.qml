pragma ComponentBehavior: Bound

import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

/**
* The media grabber card: a link field with a status chip on top, the fetched
* media and its format/quality pickers below it, and the action for whatever
* YtDlp.view currently is.
*/
OverlayDialogCard {
    id: root

    signal closeRequested

    readonly property string view: YtDlp.view
    readonly property bool downloadFailed: root.view === "error" && YtDlp.failedStep === "download"
    // A failed download keeps its card, so Retry has something to retry.
    readonly property bool hasMedia: YtDlp.title.length > 0
        && (["ready", "downloading", "done"].includes(root.view) || root.downloadFailed)
    // Format and quality are settled once the download starts.
    readonly property bool locked: root.view === "downloading" || root.view === "done"
    readonly property real sectionPadding: Appearance.spacing.lg
    readonly property real buttonHeight: Appearance.spacing.xxl + Appearance.spacing.m
    readonly property real chipHeight: Appearance.spacing.xxl - Appearance.spacing.xxs
    readonly property real borderWidth: Appearance.spacing.xxs / 2
    // The bands run edge to edge inside the border, so their outer corners
    // follow the card's rounding minus the border they sit against.
    readonly property real bandRadius: Appearance.rounding.windowRounding - root.borderWidth

    readonly property string mediaSubtitle: [YtDlp.uploader, YtDlp.platformLabel].filter(part => part.length > 0).join(" · ")
    readonly property string progressDetail: {
        const parts = [];
        if (YtDlp.selectedSize > 0)
            parts.push(`${YtDlp.formatBytes(YtDlp.selectedSize * YtDlp.progress)} / ${YtDlp.formatBytes(YtDlp.selectedSize)}`);
        if (YtDlp.speed.length > 0)
            parts.push(YtDlp.speed);
        else if (YtDlp.eta.length > 0)
            parts.push(`ETA ${YtDlp.eta}`);
        return parts.join(" · ");
    }

    // The chip at the end of the link field: what the panel is doing right now.
    readonly property var chip: {
        if (root.view === "fetching")
            return {
                icon: "progress_activity",
                label: "Fetching",
                spin: true,
                background: Appearance.colors.colSurfaceContainerHigh,
                foreground: Appearance.colors.colOnLayer1
            };
        if (root.view === "error")
            return {
                icon: root.downloadFailed ? "error" : "link_off",
                label: root.downloadFailed ? "Failed" : "Unsupported",
                spin: false,
                background: Appearance.colors.colErrorContainer,
                foreground: Appearance.colors.colOnErrorContainer
            };
        if (root.view === "done")
            return {
                icon: "check_circle",
                label: "Saved",
                spin: false,
                background: Appearance.colors.colPrimaryContainer,
                foreground: Appearance.colors.colOnPrimaryContainer
            };
        if (root.hasMedia)
            return {
                icon: YtDlp.platformIcon,
                label: YtDlp.platformLabel,
                spin: false,
                background: Appearance.colors.colSurfaceContainerHigh,
                foreground: Appearance.colors.colOnLayer1
            };
        // Text that isn't a link yet: say so instead of promising a paste
        // shortcut that would overwrite what is being typed.
        if (YtDlp.url.trim().length > 0)
            return {
                icon: "link_off",
                label: "Not a link",
                spin: false,
                background: Appearance.colors.colSurfaceContainerHigh,
                foreground: Appearance.colors.colSubtext
            };
        return {
            icon: "content_paste",
            label: "Ctrl V",
            spin: false,
            background: Appearance.colors.colSurfaceContainerHigh,
            foreground: Appearance.colors.colSubtext
        };
    }

    readonly property var hints: {
        if (root.view === "downloading")
            return [
                {
                    key: "esc",
                    label: "cancel"
                }
            ];
        if (root.view === "done")
            return [
                {
                    key: "⏎",
                    label: "new download"
                }
            ];
        if (root.view === "ready" || root.downloadFailed)
            return [
                {
                    key: "⏎",
                    label: root.downloadFailed ? "retry" : "download"
                },
                {
                    key: "esc",
                    label: "clear"
                }
            ];
        if (root.view === "error" || root.view === "fetching")
            return [
                {
                    key: "esc",
                    label: "clear"
                }
            ];
        return [
            {
                key: "^V",
                label: "paste link"
            }
        ];
    }

    // Escape walks back out of the panel a step at a time; Enter does whatever
    // the current view's primary action is.
    function handleKey(event): bool {
        if (event.key === Qt.Key_Escape) {
            if (root.view === "downloading")
                YtDlp.cancelDownload();
            else if (YtDlp.url.length > 0)
                YtDlp.clearLink();
            else
                root.closeRequested();
            return true;
        }
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            if (root.view === "ready")
                YtDlp.download();
            else if (root.downloadFailed)
                YtDlp.retry();
            else if (root.view === "done")
                YtDlp.clearLink();
            else if (root.view === "idle" || root.view === "fetching")
                YtDlp.fetch();
            return true;
        }
        return false;
    }

    Component.onCompleted: animateIn()
    onAboutToAnimateIn: urlInput.forceActiveFocus()

    focus: true

    implicitWidth: Appearance.sizes.mediaGrabberWidth + 2 * Appearance.sizes.elevationMargin
    implicitHeight: 2 * (Appearance.sizes.elevationMargin + root.borderWidth) + contentColumn.implicitHeight
    surfaceColor: Appearance.colors.colBackgroundSurfaceContainer
    surface.radius: Appearance.rounding.windowRounding
    surface.border.color: Appearance.colors.colLayer0Border
    surface.border.width: root.borderWidth
    surface.clip: true

    Keys.onPressed: event => {
        event.accepted = root.handleKey(event);
    }

    Behavior on implicitHeight {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }

    // A hairline between the card's bands.
    component Divider: Rectangle {
        Layout.fillWidth: true
        implicitHeight: Appearance.spacing.xxs / 2
        color: Appearance.colors.colOutlineVariant
    }

    // A rounded, full-width or content-width action: icon plus label.
    component PillButton: RippleButton {
        id: pill

        property string symbol: ""
        property string label: ""
        property string suffix: ""
        property color foreground: Appearance.colors.colOnLayer2

        buttonRadius: Appearance.rounding.full
        colBackground: Appearance.colors.colSurfaceContainerHigh
        colBackgroundHover: Appearance.colors.colSurfaceContainerHighestHover
        implicitHeight: root.buttonHeight
        implicitWidth: pillContent.implicitWidth + Appearance.spacing.lg * 2

        contentItem: Item {
            RowLayout {
                id: pillContent

                anchors.centerIn: parent
                spacing: Appearance.spacing.s

                MaterialSymbol {
                    text: pill.symbol
                    iconSize: Appearance.font.pixelSize.large
                    color: pill.foreground
                }
                StyledText {
                    text: pill.label
                    font.pixelSize: Appearance.font.pixelSize.smallie
                    color: pill.foreground
                }
                StyledText {
                    visible: pill.suffix.length > 0
                    text: pill.suffix
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    font.features: ({
                            "tnum": 1
                        })
                    color: pill.foreground
                    opacity: 0.75
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

    ColumnLayout {
        id: contentColumn

        // The card's surface is already inset by the elevation margin; the bands
        // run right up to its border so no rim of the surface shows around them.
        anchors.fill: parent
        anchors.margins: root.borderWidth
        spacing: 0

        // The link field, always on top
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: headerRow.implicitHeight + Appearance.spacing.m * 2
            color: Appearance.colors.colSurfaceContainerLow
            topLeftRadius: root.bandRadius
            topRightRadius: root.bandRadius

            RowLayout {
                id: headerRow

                anchors.fill: parent
                anchors.margins: Appearance.spacing.m
                anchors.leftMargin: root.sectionPadding
                anchors.rightMargin: root.sectionPadding
                spacing: Appearance.spacing.m

                MaterialSymbol {
                    text: "download"
                    iconSize: Appearance.font.pixelSize.huge
                    color: Appearance.colors.colPrimary
                }

                Item {
                    Layout.fillWidth: true
                    implicitHeight: urlInput.implicitHeight

                    StyledTextInput {
                        id: urlInput

                        anchors.fill: parent
                        clip: true
                        focus: true
                        // Editing a link mid-download would pull the rug out.
                        readOnly: root.view === "downloading"
                        color: Appearance.colors.colOnSurface
                        font.pixelSize: Appearance.font.pixelSize.huge
                        text: YtDlp.url
                        onTextEdited: YtDlp.url = text

                        Keys.onPressed: event => {
                            if (root.handleKey(event))
                                event.accepted = true;
                        }

                        StyledText {
                            anchors.fill: parent
                            visible: urlInput.text.length === 0
                            text: "Paste a link…"
                            font.pixelSize: urlInput.font.pixelSize
                            color: Appearance.colors.colSubtext
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                }

                Rectangle {
                    implicitWidth: chipRow.implicitWidth + Appearance.spacing.m * 2
                    implicitHeight: chipRow.implicitHeight + Appearance.spacing.xs
                    radius: Appearance.rounding.full
                    color: root.chip.background

                    Behavior on color {
                        animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                    }

                    RowLayout {
                        id: chipRow

                        anchors.centerIn: parent
                        spacing: Appearance.spacing.xs

                        MaterialSymbol {
                            id: chipIcon

                            text: root.chip.icon
                            iconSize: Appearance.font.pixelSize.small
                            color: root.chip.foreground

                            RotationAnimation on rotation {
                                running: root.chip.spin
                                loops: Animation.Infinite
                                from: 0
                                to: 360
                                duration: Appearance.animation.elementMove.duration * 2
                                onRunningChanged: if (!running)
                                    chipIcon.rotation = 0
                            }
                        }
                        StyledText {
                            text: root.chip.label
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: root.chip.foreground
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        // Only the empty chip offers the paste; it would
                        // otherwise overwrite whatever is in the field.
                        enabled: root.view === "idle" && YtDlp.url.trim().length === 0
                        cursorShape: Qt.PointingHandCursor
                        onClicked: YtDlp.pasteUrl()
                    }
                }
            }
        }

        // What went wrong, in yt-dlp's own words where it has any
        Divider {
            visible: root.view === "error"
        }
        Rectangle {
            visible: root.view === "error"
            Layout.fillWidth: true
            implicitHeight: errorRow.implicitHeight + Appearance.spacing.m * 2
            color: Appearance.colors.colErrorContainer

            RowLayout {
                id: errorRow

                anchors.fill: parent
                anchors.margins: Appearance.spacing.m
                anchors.leftMargin: root.sectionPadding
                anchors.rightMargin: root.sectionPadding
                spacing: Appearance.spacing.m

                MaterialSymbol {
                    Layout.alignment: Qt.AlignTop
                    text: "error"
                    iconSize: Appearance.font.pixelSize.large
                    color: Appearance.colors.colOnErrorContainer
                }
                StyledText {
                    Layout.fillWidth: true
                    text: YtDlp.errorMessage || "No downloadable media at that link"
                    font.pixelSize: Appearance.font.pixelSize.smallie
                    color: Appearance.colors.colOnErrorContainer
                    wrapMode: Text.Wrap
                }
            }
        }

        // The fetched media and its pickers
        Divider {
            visible: mediaSection.visible
        }
        ColumnLayout {
            id: mediaSection

            visible: opacity > 0
            opacity: root.hasMedia ? 1 : 0
            Layout.fillWidth: true
            spacing: 0

            transform: Translate {
                y: (1 - mediaSection.opacity) * Appearance.spacing.s
            }

            Behavior on opacity {
                animation: Appearance.animation.elementMoveEnter.numberAnimation.createObject(this)
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.margins: root.sectionPadding
                spacing: root.sectionPadding

                // The thumbnail, or a play glyph while there is none
                Rectangle {
                    id: thumb

                    Layout.preferredWidth: Appearance.sizes.mediaGrabberThumbnailWidth
                    Layout.preferredHeight: Appearance.sizes.mediaGrabberThumbnailWidth * 9 / 16
                    Layout.alignment: Qt.AlignTop
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
                        visible: YtDlp.duration.length > 0
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.margins: Appearance.spacing.xs - Appearance.spacing.xxs
                        implicitWidth: durationText.implicitWidth + Appearance.spacing.xs
                        implicitHeight: durationText.implicitHeight + Appearance.spacing.xxs
                        radius: Appearance.rounding.verysmall
                        color: ColorUtils.transparentize(Appearance.m3colors.m3surface, 0.25)

                        StyledText {
                            id: durationText

                            anchors.centerIn: parent
                            text: YtDlp.duration
                            font.pixelSize: Appearance.font.pixelSize.smallest
                            font.features: ({
                                    "tnum": 1
                                })
                            color: Appearance.m3colors.m3onSurface
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Appearance.spacing.m

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Appearance.spacing.xxs

                        StyledText {
                            Layout.fillWidth: true
                            text: YtDlp.title
                            font.pixelSize: Appearance.font.pixelSize.normal
                            color: Appearance.colors.colOnSurface
                            wrapMode: Text.Wrap
                            maximumLineCount: 2
                            elide: Text.ElideRight
                        }
                        StyledText {
                            Layout.fillWidth: true
                            text: root.mediaSubtitle
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colSubtext
                            elide: Text.ElideRight
                        }
                    }

                    // Video or audio
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: formatRow.implicitHeight + Appearance.spacing.xxs * 2
                        radius: Appearance.rounding.normal
                        color: Appearance.colors.colLayer1

                        RowLayout {
                            id: formatRow

                            anchors.fill: parent
                            anchors.margins: Appearance.spacing.xxs
                            spacing: Appearance.spacing.xxs

                            Repeater {
                                model: [
                                    {
                                        key: "video",
                                        label: "Video",
                                        symbol: "movie"
                                    },
                                    {
                                        key: "audio",
                                        label: "Audio",
                                        symbol: "music_note"
                                    }
                                ]
                                delegate: RippleButton {
                                    id: formatOption

                                    required property var modelData
                                    readonly property bool selected: YtDlp.format === modelData.key

                                    Layout.fillWidth: true
                                    implicitHeight: root.chipHeight
                                    buttonRadius: Appearance.rounding.small
                                    toggled: formatOption.selected
                                    // A settled picker stops reacting but stays
                                    // legible: it says what is being downloaded.
                                    pointingHandCursor: !root.locked
                                    rippleEnabled: !root.locked
                                    colBackgroundHover: root.locked ? colBackground : Appearance.colors.colLayer1Hover
                                    colBackgroundToggledHover: root.locked ? colBackgroundToggled : Appearance.colors.colPrimaryHover
                                    onClicked: {
                                        if (!root.locked)
                                            YtDlp.format = modelData.key;
                                    }

                                    contentItem: Item {
                                        RowLayout {
                                            anchors.centerIn: parent
                                            spacing: Appearance.spacing.xs

                                            MaterialSymbol {
                                                text: formatOption.modelData.symbol
                                                iconSize: Appearance.font.pixelSize.small
                                                color: formatOption.selected ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer1
                                            }
                                            StyledText {
                                                text: formatOption.modelData.label
                                                font.pixelSize: Appearance.font.pixelSize.smaller
                                                color: formatOption.selected ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer1
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // The qualities the site actually offers for that format
                    Flow {
                        Layout.fillWidth: true
                        spacing: Appearance.spacing.xs

                        Repeater {
                            model: YtDlp.qualities
                            delegate: RippleButton {
                                id: qualityOption

                                required property var modelData
                                readonly property bool selected: YtDlp.selectedQuality?.key === modelData.key

                                implicitHeight: root.chipHeight
                                implicitWidth: qualityLabel.implicitWidth + Appearance.spacing.m * 2
                                buttonRadius: Appearance.rounding.full
                                toggled: qualityOption.selected
                                pointingHandCursor: !root.locked
                                rippleEnabled: !root.locked
                                colBackground: "transparent"
                                colBackgroundHover: root.locked ? "transparent" : Appearance.colors.colLayer1Hover
                                colBackgroundToggled: Appearance.colors.colSecondaryContainer
                                colBackgroundToggledHover: root.locked ? colBackgroundToggled : Appearance.colors.colSecondaryContainerHover
                                colRippleToggled: Appearance.colors.colSecondaryContainerActive
                                onClicked: {
                                    if (!root.locked)
                                        YtDlp.quality = modelData.key;
                                }

                                contentItem: Item {
                                    Rectangle {
                                        anchors.fill: parent
                                        radius: Appearance.rounding.full
                                        color: "transparent"
                                        border.width: qualityOption.selected ? 0 : Appearance.spacing.xxs / 2
                                        border.color: Appearance.colors.colOutlineVariant
                                    }
                                    StyledText {
                                        id: qualityLabel

                                        anchors.centerIn: parent
                                        text: qualityOption.modelData.label
                                        font.pixelSize: Appearance.font.pixelSize.smaller
                                        color: qualityOption.selected ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnLayer1
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // The action for whatever the download is doing
            Item {
                Layout.fillWidth: true
                Layout.leftMargin: root.sectionPadding
                Layout.rightMargin: root.sectionPadding
                Layout.bottomMargin: root.sectionPadding
                implicitHeight: root.buttonHeight

                PrimaryPillButton {
                    anchors.fill: parent
                    visible: root.view === "ready"
                    symbol: "download"
                    label: "Download"
                    suffix: YtDlp.sizeLabel
                    onClicked: YtDlp.download()
                }

                ColumnLayout {
                    anchors.fill: parent
                    visible: root.view === "downloading"
                    spacing: Appearance.spacing.s

                    Item {
                        Layout.fillHeight: true
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Appearance.spacing.s

                        StyledText {
                            text: `${Math.round(YtDlp.progress * 100)}%`
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            font.features: ({
                                    "tnum": 1
                                })
                            color: Appearance.colors.colOnSurface
                        }
                        StyledText {
                            Layout.fillWidth: true
                            // yt-dlp merges or converts once the streams are in.
                            text: YtDlp.progress >= 1 ? "Finishing…" : root.progressDetail
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            font.features: ({
                                    "tnum": 1
                                })
                            color: Appearance.colors.colSubtext
                            elide: Text.ElideRight
                        }
                        RippleButton {
                            implicitWidth: Appearance.spacing.xl
                            implicitHeight: Appearance.spacing.xl
                            buttonRadius: Appearance.rounding.full
                            colBackgroundHover: Appearance.colors.colLayer1Hover
                            onClicked: YtDlp.cancelDownload()

                            StyledToolTip {
                                text: "Cancel"
                            }

                            contentItem: MaterialSymbol {
                                horizontalAlignment: Text.AlignHCenter
                                text: "close"
                                iconSize: Appearance.font.pixelSize.small
                                color: Appearance.colors.colOnLayer1
                            }
                        }
                    }

                    StyledProgressBar {
                        Layout.fillWidth: true
                        wavy: true
                        animateWave: root.view === "downloading"
                        value: YtDlp.progress
                    }

                    Item {
                        Layout.fillHeight: true
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    visible: root.view === "done"
                    spacing: Appearance.spacing.s

                    PrimaryPillButton {
                        Layout.fillWidth: true
                        visible: YtDlp.savedPath.length > 0
                        symbol: "folder_open"
                        label: "Show in folder"
                        onClicked: {
                            YtDlp.showInFolder();
                            root.closeRequested();
                        }
                    }
                    PillButton {
                        symbol: "add_link"
                        label: "New"
                        onClicked: YtDlp.clearLink()
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    visible: root.downloadFailed
                    spacing: Appearance.spacing.s

                    PrimaryPillButton {
                        Layout.fillWidth: true
                        symbol: "refresh"
                        label: "Retry"
                        onClicked: YtDlp.retry()
                    }
                    PillButton {
                        symbol: "add_link"
                        label: "New"
                        onClicked: YtDlp.clearLink()
                    }
                }
            }
        }

        // Keyboard hints for the current view
        Divider {}
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: hintFlow.implicitHeight + Appearance.spacing.m * 2
            color: Appearance.colors.colSurfaceContainerLow
            bottomLeftRadius: root.bandRadius
            bottomRightRadius: root.bandRadius

            Flow {
                id: hintFlow

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: root.sectionPadding
                anchors.rightMargin: root.sectionPadding
                spacing: Appearance.spacing.lg

                Repeater {
                    model: root.hints
                    delegate: Row {
                        id: hint

                        required property var modelData

                        spacing: Appearance.spacing.xs

                        KeyboardKey {
                            anchors.verticalCenter: parent.verticalCenter
                            key: hint.modelData.key
                            pixelSize: Appearance.font.pixelSize.smallest
                            borderColor: Appearance.colors.colOutlineVariant
                            keyColor: Appearance.colors.colLayer4Base
                            borderRadius: Appearance.rounding.unsharpenmore
                            extraBottomBorderWidth: Appearance.spacing.xxs
                        }
                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            text: hint.modelData.label
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colSubtext
                        }
                    }
                }
            }
        }
    }
}
