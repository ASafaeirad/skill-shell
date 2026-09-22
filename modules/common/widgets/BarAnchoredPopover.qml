pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.modules.common

PanelWindow {
    id: root

    property string anchorName: ""
    property real barMargin: Appearance.sizes.barHeight
    property real sideGap: Appearance.sizes.hyprlandGapsOut
    property string layerNamespace: "quickshell:popover"
    property bool dismissOnFocusGrab: true

    signal dismissed()

    function boundedPosition(wantedPosition: real, availableSize: real, popupSize: real): real {
        return BarAnchors.boundedPosition(wantedPosition, availableSize, popupSize, root.sideGap);
    }

    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0
    color: "transparent"

    WlrLayershell.namespace: root.layerNamespace

    anchors {
        top: !Config.options.bar.bottom
        bottom: Config.options.bar.bottom
        left: true
        right: false
    }

    margins {
        top: root.barMargin
        bottom: root.barMargin
        left: {
            BarAnchors.revision;
            root.visible;
            return BarAnchors.calculateLeftMargin(root.anchorName, root.screen?.width ?? 0, root.implicitWidth, root.sideGap);
        }
    }

    Component.onCompleted: {
        if (root.dismissOnFocusGrab) {
            GlobalFocusGrab.addDismissable(root);
        }
    }

    Component.onDestruction: {
        if (root.dismissOnFocusGrab) {
            GlobalFocusGrab.removeDismissable(root);
        }
    }

    Connections {
        target: GlobalFocusGrab
        enabled: root.dismissOnFocusGrab
        function onDismissed() {
            root.dismissed();
        }
    }
}
