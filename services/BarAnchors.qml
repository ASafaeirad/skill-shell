pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.modules.common

Singleton {
    id: root

    property int revision: 0
    property var anchors: ({})

    signal anchorRegistered(string name)
    signal anchorUnregistered(string name)
    signal anchorUpdated(string name)

    function register(name: string, anchorItem: var): void {
        if (!name) return;
        const updated = Object.assign({}, root.anchors);
        updated[name] = anchorItem;
        root.anchors = updated;
        root.revision++;
        root.anchorRegistered(name);
    }

    function unregister(name: string, anchorItem: var): void {
        if (!name) return;
        if (root.anchors && root.anchors[name] === anchorItem) {
            const updated = Object.assign({}, root.anchors);
            delete updated[name];
            root.anchors = updated;
            root.revision++;
            root.anchorUnregistered(name);
        }
    }

    function notifyAnchorUpdated(name: string): void {
        root.revision++;
        root.anchorUpdated(name);
    }

    function get(name: string): var {
        return root.anchors ? (root.anchors[name] ?? null) : null;
    }

    function getItem(name: string): var {
        const anchor = root.get(name);
        return anchor?.item ?? null;
    }

    function boundedPosition(wantedPosition: real, availableSize: real, popupSize: real, sideGap: real): real {
        if (availableSize <= 0)
            return wantedPosition;
        const gap = (sideGap !== undefined && sideGap !== null) ? sideGap : Appearance.sizes.hyprlandGapsOut;
        return Math.max(gap, Math.min(wantedPosition, availableSize - popupSize - gap));
    }

    function calculateLeftMargin(name: string, availableWidth: real, popoverWidth: real, sideGap: real): real {
        const gap = (sideGap !== undefined && sideGap !== null) ? sideGap : Appearance.sizes.hyprlandGapsOut;
        const anchor = root.get(name);
        const item = anchor?.item ?? anchor;

        if (item && item.parent) {
            let targetX = -1;
            try {
                targetX = item.mapToItem(null, 0, 0).x;
            } catch (e) {
                targetX = -1;
            }
            if (targetX >= 0) {
                const targetWidth = item.width;
                const wantedPosition = targetX + (targetWidth - popoverWidth) / 2;
                return root.boundedPosition(wantedPosition, availableWidth, popoverWidth, gap);
            }
        }

        return availableWidth > 0 ? root.boundedPosition((availableWidth - popoverWidth) / 2, availableWidth, popoverWidth, gap) : 0;
    }
}
