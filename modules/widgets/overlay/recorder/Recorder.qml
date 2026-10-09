pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.m3 as M3
import qs.modules.widgets.overlay

StyledOverlayWidget {
    id: root
    minimumWidth: 310
    minimumHeight: 130

    contentItem: OverlayBackground {
        id: contentItem
        radius: root.contentRadius
        property real padding: Appearance.spacing.s
        ColumnLayout {
            id: contentColumn
            anchors.centerIn: parent
            spacing: Appearance.spacing.s + Appearance.spacing.xxs

            Row {
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                spacing: Appearance.spacing.s + Appearance.spacing.xxs

                M3.Fab {
                    variant: "secondary"
                    iconText: "screenshot_region"
                    tooltip: "Screenshot region"
                    onClicked: {
                        OverlayContext.overlayOpen = false;
                        GlobalStates.regionCaptureRequested();
                    }
                }

                M3.Fab {
                    variant: "secondary"
                    iconText: "photo_camera"
                    tooltip: "Screenshot"
                    onClicked: {
                        OverlayContext.overlayOpen = false;
                        Quickshell.execDetached(["bash", "-c", "grim - | wl-copy"]);
                    }
                }

                M3.Fab {
                    variant: "secondary"
                    iconText: "screen_record"
                    tooltip: "Record region"
                    onClicked: {
                        OverlayContext.overlayOpen = false;
                        GlobalStates.regionCaptureRequested();
                    }
                }
                
                M3.Fab {
                    variant: "secondary"
                    iconText: "capture"
                    tooltip: "Record screen"
                    onClicked: {
                        OverlayContext.overlayOpen = false;
                        Quickshell.execDetached([Directories.recordScriptPath, "--fullscreen", "--sound"]);
                    }
                }
            }

            M3.Button {
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                variant: "tonal"
                materialIcon: "animated_images"
                text: "Open recordings folder"
                onClicked: {
                    OverlayContext.overlayOpen = false;
                    Qt.openUrlExternally(`file://${Config.options.screenRecord.savePath}`);
                }
            }
        }
    }
}
