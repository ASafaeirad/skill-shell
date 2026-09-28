pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

import qs.modules.common
import qs.modules.common.utils
import qs.modules.common.widgets
import qs.modules.common.m3 as M3
import qs.services

PanelWindow {
    id: root

    // Interface
    signal dismiss

    // Window props
    visible: false
    // color: Appearance.colors.colLayer0
    color: "black"
    WlrLayershell.namespace: "quickshell:regionSelector"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    exclusionMode: ExclusionMode.Ignore
    anchors {
        left: true
        right: true
        top: true
        bottom: true
    }

    // Config
    readonly property string screenshotDir: Directories.screenshotTemp
    readonly property string screenshotPath: `${root.screenshotDir}/image-${screen.name}`

    // Preparation
    property bool screenshotReady: false

    function performTranslation() {
        screenshotReady = true;
    }

    TempScreenshotProcess {
        id: screenshotProc
        running: true
        screen: root.screen
        screenshotDir: root.screenshotDir
        screenshotPath: root.screenshotPath
        onExited: (_, __) => {
            root.visible = true;
            root.performTranslation();
        }
    }

    // Actual content
    property real scale: 1.0
    property real contentX: 0
    property real contentY: 0

    MouseArea {
        anchors.fill: parent
        clip: true

        property real lastX: 0
        property real lastY: 0

        cursorShape: Qt.SizeAllCursor

        onPressed: mouse => {
            lastX = mouse.x;
            lastY = mouse.y;
        }

        onPositionChanged: mouse => {
            if (pressed) {
                root.contentX += (mouse.x - lastX);
                root.contentY += (mouse.y - lastY);
                lastX = mouse.x;
                lastY = mouse.y;
            }
        }

        onWheel: event => {
            const zoomFactor = event.angleDelta.y > 0 ? 1.1 : 0.9;
            const oldScale = root.scale;
            const newScale = Math.min(Math.max(0.1, oldScale * zoomFactor), 5);

            if (newScale !== oldScale) {
                // Determine mouse position relative to the content's unscaled origin
                const localX = (event.x - root.contentX) / oldScale;
                const localY = (event.y - root.contentY) / oldScale;

                // Apply zoom
                root.scale = newScale;

                // Shift offsets to keep the same local point under the cursor
                root.contentX = event.x - (localX * newScale);
                root.contentY = event.y - (localY * newScale);
            }
        }

        ScreencopyView { // Freeze screen
            id: screencopy
            width: parent.width
            height: parent.height

            x: root.contentX
            y: root.contentY
            scale: root.scale
            transformOrigin: Item.TopLeft

            live: false
            captureSource: root.screen
        }

        Loader {
            width: parent.width * root.scale
            height: parent.height * root.scale

            x: root.contentX
            y: root.contentY

            active: root.screenshotReady
            sourceComponent: ScreenTextOverlay {
                screenshotPath: root.screenshotPath
                scaleFactor: root.scale
                onDismiss: root.dismiss()
            }
        }
    }

    Row {
        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: parent.bottom
            bottomMargin: -height
        }
        Behavior on anchors.bottomMargin {
            animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
        }
        Component.onCompleted: {
            anchors.bottomMargin = 8;
        }

        spacing: 6

        M3.Toolbar {
            id: toolbar
            focus: root.visible
            Keys.onPressed: event => { // Esc to close
                if (event.key === Qt.Key_Escape) {
                    root.dismiss();
                }
            }
            spacing: 0

            M3.IconButton {
                id: keyButton
                toggleable: true
                selectedVariant: "tonal"
                onClicked: {
                    selected = !selected
                    if (selected) keyInput.forceActiveFocus()
                }
                materialIcon: "key"
                tooltip: "Key input"
            }

            Revealer {
                reveal: keyButton.selected
                Layout.fillHeight: true

                RowLayout {
                    anchors.left: parent.left
                    spacing: 6
                    Item {} // extra padding
                    M3.ToolbarTextField {
                        id: keyInput
                        implicitWidth: 400
                        placeholderText: "Paste service account key JSON here"
                        inputMethodHints: Qt.ImhSensitiveData
                        onAccepted: submit()

                        function submit() {
                            const success = GoogleCloud.setKeyJson(text);
                            if (!success) {
                                invalidJsonAnimation.restart();
                            } else {
                                text = "";
                                keyButton.selected = false;
                            }
                        }

                        ErrorShakeAnimation {
                            id: invalidJsonAnimation
                            target: keyInput
                        }
                    }
                    M3.IconButton {
                        id: submitButton
                        onClicked: keyInput.submit()
                        materialIcon: "check"
                        tooltip: "Confirm"
                        toggleable: true
                        selectedVariant: "tonal"
                        selected: keyInput.text.length > 0
                    }
                }
            }
        }

        M3.Fab {
            anchors.verticalCenter: parent.verticalCenter
            variant: "tertiary"
            size: "toolbar"
            elevated: true
            iconText: "close"
            tooltip: "Close"
            onClicked: root.dismiss()
        }
    }
}
