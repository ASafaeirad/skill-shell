pragma ComponentBehavior: Bound
import qs.modules.common
import qs.modules.common.utils
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.common.m3 as M3
import qs.services
import QtQuick
import QtQuick.Controls
import Qt.labs.synchronizer
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

PanelWindow {
    id: root
    // A mapped, transparent window lets ScreencopyView receive its first frame.
    visible: true
    color: "transparent"
    WlrLayershell.namespace: "quickshell:regionSelector"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: screenshotReady && phase === RegionSelection.Phase.Select ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    anchors {
        left: true
        right: true
        top: true
        bottom: true
    }

    // Modes
    // TODO: Ask: sidebar AI
    enum SnipAction { Copy, Edit, Search, CharRecognition, Record, RecordWithSound }
    enum Phase { Select, Post }
    property var action: RegionSelection.SnipAction.Copy
    property var phase: RegionSelection.Phase.Select
    // Capture actions can be switched between in the overlay; search/ocr are one-shot
    readonly property var captureModeActions: [
        RegionSelection.SnipAction.Copy,
        RegionSelection.SnipAction.Record,
        RegionSelection.SnipAction.RecordWithSound
    ]
    readonly property bool captureModes: root.captureModeActions.includes(root.action)
    property bool fullscreen: false
    function cycleCaptureMode(step) {
        if (!root.captureModes) return;
        const current = Math.max(0, root.captureModeActions.indexOf(root.action));
        const count = root.captureModeActions.length;
        root.setCaptureMode((current + step + count) % count);
    }
    function setCaptureMode(index) {
        if (!root.captureModes) return;
        root.action = root.captureModeActions[index];
    }
    signal dismiss()
    Component.onDestruction: {
        screenshotProc.restoreCursor();
        if (!root.screenshotActionStarted)
            Quickshell.execDetached(["rm", "-f", root.screenshotPath]);
    }

    function dismissAndRestoreCursor() {
        screenshotProc.restoreCursor();
        root.dismiss();
    }

    // Styles
    property string screenshotDir: Directories.screenshotTemp
    property color overlayColor: ColorUtils.transparentize(Appearance.m3colors.m3scrim, 0.4)
    property color brightText: Appearance.m3colors.darkmode ? Appearance.colors.colOnLayer0 : Appearance.colors.colLayer0
    property color brightSecondary: Appearance.m3colors.darkmode ? Appearance.colors.colSecondary : Appearance.colors.colOnSecondary
    property color brightTertiary: Appearance.m3colors.darkmode ? Appearance.colors.colTertiary : Qt.lighter(Appearance.colors.colPrimary)
    property color selectionBorderColor: ColorUtils.mix(brightText, brightSecondary, 0.5)
    property color windowBorderColor: brightSecondary
    property color windowFillColor: ColorUtils.transparentize(windowBorderColor, 0.85)
    property color imageBorderColor: brightTertiary
    property color imageFillColor: ColorUtils.transparentize(imageBorderColor, 0.85)
    readonly property real targetRegionOpacity: 0.3 // was targetRegions.opacity
    readonly property real contentRegionOpacity: 0.8 // was targetRegions.contentRegionOpacity

    // Vars for indicators
    readonly property var windows: [...HyprlandData.windowList].sort((a, b) => {
        // Sort floating=true windows before others
        if (a.floating === b.floating) return 0;
        return a.floating ? -1 : 1;
    })
    readonly property var layers: HyprlandData.layers
    readonly property real falsePositivePreventionRatio: 0.5

    // Screen & interaction vars
    readonly property HyprlandMonitor hyprlandMonitor: Hyprland.monitorFor(screen)
    readonly property real monitorScale: hyprlandMonitor.scale
    readonly property real monitorOffsetX: hyprlandMonitor.x
    readonly property real monitorOffsetY: hyprlandMonitor.y
    property int activeWorkspaceId: hyprlandMonitor.activeWorkspace?.id ?? 0
    // Uncompressed scratch frames avoid PNG encoding on the shell's UI thread.
    // ScreenshotAction encodes the selected region as PNG after selection.
    property string screenshotPath: `${root.screenshotDir}/image-${screen.name}-${Date.now()}.ppm`
    property bool screenshotReady: false
    property bool captureFailed: false
    property bool screenshotActionStarted: false
    readonly property real captureStartedAt: Date.now()
    property int captureElapsedMs: 0

    function failCapture(reason) {
        if (root.captureFailed) return;
        root.captureFailed = true;
        screenshotProc.running = false;
        screenshotProc.restoreCursor();
        root.visible = false;
        console.warn("[Region Selector] Capture failed for", root.screen.name, reason);
    }
    property real dragStartX: 0
    property real dragStartY: 0
    property real draggingX: 0
    property real draggingY: 0
    property real dragDiffX: 0
    property real dragDiffY: 0
    property bool draggedAway: (dragDiffX !== 0 || dragDiffY !== 0)
    property bool dragging: false
    property var mouseButton: null
    property var imageRegions: []
    readonly property list<var> windowRegions: RegionFunctions.filterWindowRegionsByLayers(
        root.windows.filter(w => w.workspace.id === root.activeWorkspaceId),
        root.layerRegions
    ).map(window => {
        return {
            at: [window.at[0] - root.monitorOffsetX, window.at[1] - root.monitorOffsetY],
            size: [window.size[0], window.size[1]],
            class: window.class,
            title: window.title,
        }
    })
    readonly property list<var> layerRegions: {
        const layersOfThisMonitor = root.layers[root.hyprlandMonitor.name]
        const topLayers = layersOfThisMonitor?.levels["2"]
        if (!topLayers) return [];
        const nonBarTopLayers = topLayers
            .filter(layer => !layer.namespace.includes(":bar"))
            .map(layer => {
            return {
                at: [layer.x, layer.y],
                size: [layer.w, layer.h],
                namespace: layer.namespace,
            }
        })
        const offsetAdjustedLayers = nonBarTopLayers.map(layer => {
            return {
                at: [layer.at[0] - root.monitorOffsetX, layer.at[1] - root.monitorOffsetY],
                size: layer.size,
                namespace: layer.namespace,
            }
        });
        return offsetAdjustedLayers;
    }

    // Config
    property bool enableWindowRegions: Config.options.regionSelector.targetRegions.windows
    property bool enableLayerRegions: Config.options.regionSelector.targetRegions.layers
    property bool enableContentRegions: Config.options.regionSelector.targetRegions.content

    // Target
    property real targetedRegionX: -1
    property real targetedRegionY: -1
    property real targetedRegionWidth: 0
    property real targetedRegionHeight: 0
    function targetedRegionValid() {
        return (root.targetedRegionX >= 0 && root.targetedRegionY >= 0)
    }
    function setRegionToTargeted() {
        const padding = 5; // was targetRegions.selectionPadding; keeps borders from being cut off
        root.regionX = root.targetedRegionX - padding;
        root.regionY = root.targetedRegionY - padding;
        root.regionWidth = root.targetedRegionWidth + padding * 2;
        root.regionHeight = root.targetedRegionHeight + padding * 2;
    }

    function updateTargetedRegion(x, y) {
        // Image regions
        const clickedRegion = root.imageRegions.find(region => {
            return region.at[0] <= x && x <= region.at[0] + region.size[0] && region.at[1] <= y && y <= region.at[1] + region.size[1];
        });
        if (clickedRegion) {
            root.targetedRegionX = clickedRegion.at[0];
            root.targetedRegionY = clickedRegion.at[1];
            root.targetedRegionWidth = clickedRegion.size[0];
            root.targetedRegionHeight = clickedRegion.size[1];
            return;
        }

        // Layer regions
        const clickedLayer = root.layerRegions.find(region => {
            return region.at[0] <= x && x <= region.at[0] + region.size[0] && region.at[1] <= y && y <= region.at[1] + region.size[1];
        });
        if (clickedLayer) {
            root.targetedRegionX = clickedLayer.at[0];
            root.targetedRegionY = clickedLayer.at[1];
            root.targetedRegionWidth = clickedLayer.size[0];
            root.targetedRegionHeight = clickedLayer.size[1];
            return;
        }

        // Window regions
        const clickedWindow = root.windowRegions.find(region => {
            return region.at[0] <= x && x <= region.at[0] + region.size[0] && region.at[1] <= y && y <= region.at[1] + region.size[1];
        });
        if (clickedWindow) {
            root.targetedRegionX = clickedWindow.at[0];
            root.targetedRegionY = clickedWindow.at[1];
            root.targetedRegionWidth = clickedWindow.size[0];
            root.targetedRegionHeight = clickedWindow.size[1];
            return;
        }

        root.targetedRegionX = -1;
        root.targetedRegionY = -1;
        root.targetedRegionWidth = 0;
        root.targetedRegionHeight = 0;
    }

    property real regionWidth: Math.abs(draggingX - dragStartX)
    property real regionHeight: Math.abs(draggingY - dragStartY)
    property real regionX: Math.min(dragStartX, draggingX)
    property real regionY: Math.min(dragStartY, draggingY)

    // Screenshot stuff
    TempScreenshotProcess {
        id: screenshotProc
        running: true
        screen: root.screen
        screenshotDir: root.screenshotDir
        screenshotPath: root.screenshotPath
        keepCursorHidden: true
        captureToFile: false
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0 || exitStatus !== 0) {
                root.failCapture("preparation failed");
                return;
            }
            root.preparationDone = !checkRecordingProc.running;
        }
    }
    // A stalled output must not leave an invisible selector or a hidden cursor.
    // Fail only this monitor so another monitor can still finish opening.
    Timer {
        interval: 3000
        running: !root.screenshotReady && !root.captureFailed
        onTriggered: root.failCapture("timed out waiting for a screen frame")
    }
    property bool recordingShouldStop: false
    Process {
        id: checkRecordingProc
        // The recording may have been started from any capture mode, so look for a
        // running recorder whenever the overlay could toggle one off
        running: root.captureModes
        command: ["pidof", "wf-recorder"]
        onExited: (exitCode, exitStatus) => {
            root.recordingShouldStop = (exitCode === 0);
            root.preparationDone = !screenshotProc.running
        }
    }
    property bool preparationDone: false
    onPreparationDoneChanged: {
        if (!preparationDone) return;
        if (root.captureModes && root.recordingShouldStop) {
            Quickshell.execDetached([Directories.recordScriptPath]);
            root.dismissAndRestoreCursor();
            return;
        }
    }

    Process {
        id: imageDetectionProcess
        command: ["bash", "-c", `${Directories.scriptPath}/images/find-regions-venv.sh `
            + `--hyprctl `
            + `--image '${StringUtils.shellSingleQuoteEscape(root.screenshotPath)}' `
            + `--max-width ${Math.round(root.screen.width * root.falsePositivePreventionRatio)} `
            + `--max-height ${Math.round(root.screen.height * root.falsePositivePreventionRatio)} `]
        stdout: StdioCollector {
            id: imageDimensionCollector
            onStreamFinished: {
                if (!text.trim()) return;
                imageRegions = RegionFunctions.filterImageRegions(
                    JSON.parse(imageDimensionCollector.text),
                    root.windowRegions
                );
            }
        }
    }

    function getScreenshotAction() {
        switch(root.action) {
            case RegionSelection.SnipAction.Copy:
                return ScreenshotAction.Action.Copy;
            case RegionSelection.SnipAction.Edit:
                return ScreenshotAction.Action.Edit;
            case RegionSelection.SnipAction.Search:
                return ScreenshotAction.Action.Search;
            case RegionSelection.SnipAction.CharRecognition:
                return ScreenshotAction.Action.CharRecognition;
            case RegionSelection.SnipAction.Record:
                return ScreenshotAction.Action.Record;
            case RegionSelection.SnipAction.RecordWithSound:
                return ScreenshotAction.Action.RecordWithSound;
            default:
                console.warn("[Region Selector] Unknown snip action, skipping snip.");
                root.dismissAndRestoreCursor();
                return;
        }
    }

    // Execution after selection
    function snip() {
        if (!root.screenshotReady) return;
        if (root.fullscreen) {
            root.regionX = 0;
            root.regionY = 0;
            root.regionWidth = root.screen.width;
            root.regionHeight = root.screen.height;
        }
        // Validity check
        if (root.regionWidth <= 0 || root.regionHeight <= 0) {
            console.warn("[Region Selector] Invalid region size, skipping snip.");
            root.dismissAndRestoreCursor();
            return;
        }

        // Clamp region to screen bounds
        root.regionX = Math.max(0, Math.min(root.regionX, root.screen.width - root.regionWidth));
        root.regionY = Math.max(0, Math.min(root.regionY, root.screen.height - root.regionHeight));
        root.regionWidth = Math.max(0, Math.min(root.regionWidth, root.screen.width - root.regionX));
        root.regionHeight = Math.max(0, Math.min(root.regionHeight, root.screen.height - root.regionY));

        // Adjust action
        if (root.action === RegionSelection.SnipAction.Copy || root.action === RegionSelection.SnipAction.Edit) {
            root.action = root.mouseButton === Qt.RightButton ? RegionSelection.SnipAction.Edit : RegionSelection.SnipAction.Copy;
        }

        const screenshotDir = Config.options.screenSnip.savePath !== "" ? //
            Config.options.screenSnip.savePath : "";
        var screenshotAction = root.getScreenshotAction();
        const isRecording = root.action === RegionSelection.SnipAction.Record
            || root.action === RegionSelection.SnipAction.RecordWithSound;
        const command = root.fullscreen && isRecording
            ? [Directories.recordScriptPath, "--fullscreen", "--output", root.screen.name,
                ...(root.action === RegionSelection.SnipAction.RecordWithSound ? ["--sound"] : [])]
            : ScreenshotAction.getCommand(
            root.regionX * root.monitorScale, //
            root.regionY * root.monitorScale, //
            root.regionWidth * root.monitorScale,//
            root.regionHeight * root.monitorScale, //
            root.screenshotPath, //
            screenshotAction, //
            screenshotDir
        )
        root.screenshotActionStarted = !isRecording;
        Quickshell.execDetached(command);
        if (root.fullscreen && isRecording) {
            root.dismissAndRestoreCursor();
            return;
        }
        if (root.action == RegionSelection.SnipAction.Record || root.action == RegionSelection.SnipAction.RecordWithSound) {
            root.phase = RegionSelection.Phase.Post
            // Remap the surface: the compositor won't return keyboard focus to the
            // window below on an interactivity change alone, only on unmap
            root.visible = false
            Qt.callLater(() => root.visible = true)
        } else {
            root.dismissAndRestoreCursor();
        }
    }

    // Only clickable in Selection phase
    mask: Region {
        item: root.screenshotReady && root.phase === RegionSelection.Phase.Select ? mouseArea : null
    }

    ScreencopyView { // For freezing
        id: screencopyView
        anchors.fill: parent
        live: false
        paintCursor: false
        captureSource: root.preparationDone && !root.captureFailed ? root.screen : null
        visible: root.phase === RegionSelection.Phase.Select

        onHasContentChanged: {
            if (!hasContent) return;
            // Save exactly the frame shown by the selector. grim -o can wait on
            // unrelated outputs when their logical monitor rectangles overlap.
            const started = grabToImage(result => {
                if (root.captureFailed) return;
                if (!result.saveToFile(root.screenshotPath)) {
                    root.failCapture("could not save the frozen frame");
                    return;
                }
                root.screenshotReady = true;
                root.captureElapsedMs = Date.now() - root.captureStartedAt;
                screenshotProc.restoreCursor();
                if (root.enableContentRegions) imageDetectionProcess.running = true;
            }, sourceSize);
            if (!started) root.failCapture("could not read the frozen frame");
        }

        focus: root.visible
        Keys.onPressed: (event) => { // Esc to close, Tab to switch capture mode
            if (event.key === Qt.Key_Escape) {
                root.dismissAndRestoreCursor();
            } else if (event.key === Qt.Key_Tab) {
                root.cycleCaptureMode(1);
                event.accepted = true;
            } else if (event.key === Qt.Key_Backtab) {
                root.cycleCaptureMode(-1);
                event.accepted = true;
            } else if (root.fullscreen && (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)) {
                root.snip();
                event.accepted = true;
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        visible: root.screenshotReady
        cursorShape: Qt.CrossCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        hoverEnabled: true

        // Controls
        onPressed: (mouse) => {
            if (root.fullscreen) return;
            root.dragStartX = mouse.x;
            root.dragStartY = mouse.y;
            root.draggingX = mouse.x;
            root.draggingY = mouse.y;
            root.dragging = true;
            root.mouseButton = mouse.button;
        }
        onReleased: (mouse) => {
            if (root.fullscreen) {
                root.snip();
                return;
            }
            // Detect if it was a click -> Try to select targeted region
            if (root.draggingX === root.dragStartX && root.draggingY === root.dragStartY) {
                if (root.targetedRegionValid()) {
                    root.setRegionToTargeted();
                }
            }
            root.snip();
        }
        onPositionChanged: (mouse) => {
            if (root.fullscreen) return;
            root.updateTargetedRegion(mouse.x, mouse.y);
            if (!root.dragging) return;
            root.draggingX = mouse.x;
            root.draggingY = mouse.y;
            root.dragDiffX = mouse.x - root.dragStartX;
            root.dragDiffY = mouse.y - root.dragStartY;
        }

        RectCornersSelectionDetails {
            z: 2
            anchors.fill: parent
            regionX: root.regionX
            regionY: root.regionY
            regionWidth: root.regionWidth
            regionHeight: root.regionHeight
            mouseX: mouseArea.mouseX
            mouseY: mouseArea.mouseY
            color: root.selectionBorderColor
            overlayColor: root.overlayColor
            breathingBorderOnly: root.phase === RegionSelection.Phase.Post
        }

        // The thing to the bottom-right with an icon
        CursorGuide {
            z: 9999
            visible: root.phase === RegionSelection.Phase.Select
            x: root.dragging ? root.regionX + root.regionWidth : mouseArea.mouseX
            y: root.dragging ? root.regionY + root.regionHeight : mouseArea.mouseY
            action: root.action
        }

        // Window regions
        Repeater {
            model: ScriptModel {
                values: {
                    if (root.phase === RegionSelection.Phase.Select && root.enableWindowRegions) {
                        return root.windowRegions
                    } else {
                        return []
                    }
                }
            }
            delegate: TargetRegion {
                z: 2
                required property var modelData
                clientDimensions: modelData
                targeted: !root.draggedAway && //
                    (root.targetedRegionX === modelData.at[0]  //
                    && root.targetedRegionY === modelData.at[1] //
                    && root.targetedRegionWidth === modelData.size[0] //
                    && root.targetedRegionHeight === modelData.size[1])

                opacity: root.draggedAway ? 0 : root.targetRegionOpacity
                borderColor: root.windowBorderColor
                fillColor: targeted ? root.windowFillColor : "transparent"
                radius: Appearance.rounding.windowRounding
            }
        }

        // Layer regions
        Repeater {
            model: ScriptModel {
                values: {
                    if (root.phase === RegionSelection.Phase.Select && root.enableLayerRegions) {
                        return root.layerRegions
                    } else {
                        return []
                    }
                }
            }
            delegate: TargetRegion {
                z: 3
                required property var modelData
                clientDimensions: modelData
                targeted: !root.draggedAway &&
                    (root.targetedRegionX === modelData.at[0]
                    && root.targetedRegionY === modelData.at[1]
                    && root.targetedRegionWidth === modelData.size[0]
                    && root.targetedRegionHeight === modelData.size[1])

                opacity: root.draggedAway ? 0 : root.targetRegionOpacity
                borderColor: root.windowBorderColor
                fillColor: targeted ? root.windowFillColor : "transparent"
                radius: Appearance.rounding.windowRounding
            }
        }

        // Content regions
        Repeater {
            model: ScriptModel {
                values: {
                    if (root.phase === RegionSelection.Phase.Select && root.enableContentRegions) {
                        return root.imageRegions
                    } else {
                        return []
                    }
                }
            }
            delegate: TargetRegion {
                z: 4
                required property var modelData
                clientDimensions: modelData
                targeted: !root.draggedAway &&
                    (root.targetedRegionX === modelData.at[0]
                    && root.targetedRegionY === modelData.at[1]
                    && root.targetedRegionWidth === modelData.size[0]
                    && root.targetedRegionHeight === modelData.size[1])

                opacity: root.draggedAway ? 0 : root.contentRegionOpacity
                borderColor: root.imageBorderColor
                fillColor: targeted ? root.imageFillColor : "transparent"
            }
        }

        // Controls
        Row {
            id: regionSelectionControls
            z: 10
            visible: root.phase === RegionSelection.Phase.Select
            anchors {
                horizontalCenter: parent.horizontalCenter
                bottom: parent.bottom
                bottomMargin: -height
            }
            opacity: 0
            Connections {
                target: root
                function onScreenshotReadyChanged() {
                    if (!root.screenshotReady) return;
                    regionSelectionControls.anchors.bottomMargin = Appearance.spacing.s;
                    regionSelectionControls.opacity = 1;
                }
            }
            Behavior on opacity {
                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
            }
            Behavior on anchors.bottomMargin {
                animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
            }
            spacing: Appearance.spacing.xs

            M3.Toolbar {
                visible: root.captureModes
                anchors.verticalCenter: parent.verticalCenter

                M3.Tabs {
                    variant: "compact"
                    currentIndex: root.fullscreen ? 1 : 0
                    onCurrentIndexChanged: root.fullscreen = currentIndex === 1
                    M3.Tab { variant: "compact"; materialIcon: "screenshot_region"; text: "Select region" }
                    M3.Tab { variant: "compact"; materialIcon: "fullscreen"; text: "Fullscreen" }
                }
            }

            OptionsToolbar {
                anchors.verticalCenter: parent.verticalCenter
                captureModes: root.captureModes
                fullscreen: root.fullscreen
                // Nothing to switch between for search/ocr
                visible: root.captureModes
                Synchronizer on action {
                    property alias source: root.action
                }
                onCaptureModeSelected: index => root.setCaptureMode(index);
                onCaptureRequested: root.snip();
                onDismiss: root.dismissAndRestoreCursor();
            }
            M3.Fab {
                anchors.verticalCenter: parent.verticalCenter
                variant: "tertiary"
                size: "toolbar"
                elevated: true
                iconText: "close"
                tooltip: "Close"
                onClicked: root.dismissAndRestoreCursor();
            }
        }

    }
}
