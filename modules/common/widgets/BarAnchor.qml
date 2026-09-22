pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.services

Item {
    id: root

    visible: false
    width: 0
    height: 0

    property string name: ""
    property Item item: parent

    readonly property real windowX: {
        BarAnchors.revision;
        if (root.item && root.item.parent) {
            try {
                return root.item.mapToItem(null, 0, 0).x;
            } catch (e) {
                return -1;
            }
        }
        return -1;
    }

    readonly property real itemWidth: root.item ? root.item.width : 0

    property var _hookedItems: []
    property string _registeredName: ""

    function update(): void {
        BarAnchors.notifyAnchorUpdated(root.name);
    }

    function rehook(): void {
        hookAncestors();
        root.update();
    }

    function hookAncestors(): void {
        unhookAncestors();
        let p = root.item;
        let hooked = [];
        while (p) {
            try {
                p.xChanged.connect(root.update);
                p.widthChanged.connect(root.update);
                p.visibleChanged.connect(root.update);
                p.parentChanged.connect(root.rehook);
                hooked.push(p);
            } catch (e) {}
            p = p.parent;
        }
        root._hookedItems = hooked;
    }

    function unhookAncestors(): void {
        for (let i = 0; i < root._hookedItems.length; i++) {
            let p = root._hookedItems[i];
            try {
                p.xChanged.disconnect(root.update);
                p.widthChanged.disconnect(root.update);
                p.visibleChanged.disconnect(root.update);
                p.parentChanged.disconnect(root.rehook);
            } catch (e) {}
        }
        root._hookedItems = [];
    }

    function registerAnchor(): void {
        if (root._registeredName && root._registeredName !== root.name) {
            BarAnchors.unregister(root._registeredName, root);
            root._registeredName = "";
        }
        if (root.name) {
            root._registeredName = root.name;
            BarAnchors.register(root.name, root);
            hookAncestors();
            root.update();
        }
    }

    onNameChanged: registerAnchor()
    onItemChanged: {
        hookAncestors();
        root.update();
    }

    Component.onCompleted: {
        registerAnchor();
    }

    Component.onDestruction: {
        unhookAncestors();
        if (root._registeredName) {
            BarAnchors.unregister(root._registeredName, root);
        }
    }
}
