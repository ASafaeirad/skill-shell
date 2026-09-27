import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.models.quickToggles
import qs.modules.common.m3 as M3

Item {
    id: root

    property int buttonIndex: 0
    property var buttonData: null
    property bool expandedSize: cellSize > 1
    property real baseCellWidth: 0
    property real baseCellHeight: 0
    property real cellSpacing: 0
    property int cellSize: buttonData?.size ?? 1
    property QuickToggleModel toggleModel
    property string name: toggleModel?.name ?? ""
    property string statusText: toggleModel?.hasStatusText
        ? (toggleModel?.statusText || (selected ? "On" : "Off")) : ""
    property string tooltipText: toggleModel?.tooltipText ?? ""
    property string buttonIcon: toggleModel?.icon ?? "close"
    property bool available: toggleModel?.available ?? true
    property bool selected: toggleModel?.toggled ?? false
    property var mainAction: toggleModel?.mainAction ?? null
    property var altAction: toggleModel?.hasMenu ? (() => root.openMenu()) : (toggleModel?.altAction ?? null)
    property bool editMode: false
    property real baseWidth: baseCellWidth * cellSize + cellSpacing * (cellSize - 1)
    property real baseHeight: baseCellHeight
    property real radius: expandedSize ? Appearance.rounding.large : Appearance.rounding.full

    signal openMenu()

    implicitWidth: baseWidth
    implicitHeight: baseHeight
    Layout.preferredWidth: baseWidth
    Layout.preferredHeight: baseHeight

    opacity: 0
    Component.onCompleted: opacity = 1
    Behavior on opacity {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }
    Behavior on baseWidth {
        animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
    }
    Behavior on baseHeight {
        animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
    }

    Loader {
        id: controlLoader
        anchors.fill: parent
        sourceComponent: root.expandedSize ? wideButton : compactButton
    }

    Component {
        id: compactButton
        M3.IconButton {
            width: root.width
            height: root.height
            variant: "filled"
            toggleable: true
            selected: root.selected
            materialIcon: root.buttonIcon
            enabled: root.available && !root.editMode
            altAction: root.altAction
            onClicked: if (root.mainAction) root.mainAction()
        }
    }

    Component {
        id: wideButton
        M3.Button {
            width: root.width
            height: root.height
            tileLayout: true
            variant: "tonal"
            selected: root.selected && !root.altAction
            materialIcon: root.buttonIcon
            text: root.name
            supportingText: root.statusText
            leadingAction: root.altAction ? root.mainAction : null
            leadingSelected: root.selected
            enabled: root.available && !root.editMode
            altAction: root.altAction
            onClicked: {
                if (root.altAction) root.altAction()
                else if (root.mainAction) root.mainAction()
            }
        }
    }

    MouseArea {
        id: editModeInteraction
        visible: root.editMode
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        acceptedButtons: Qt.AllButtons

        function toggleEnabled() {
            const index = root.buttonIndex;
            const toggleList = Config.options.sidebar.quickToggles.android.toggles;
            const buttonType = root.buttonData.type;
            if (!toggleList.find(toggle => toggle.type === buttonType))
                toggleList.push({ type: buttonType, size: 1 });
            else
                toggleList.splice(index, 1);
        }

        function toggleSize() {
            const index = root.buttonIndex;
            const toggleList = Config.options.sidebar.quickToggles.android.toggles;
            const buttonType = root.buttonData.type;
            if (!toggleList.find(toggle => toggle.type === buttonType)) return;
            toggleList[index].size = 3 - toggleList[index].size;
        }

        function movePositionBy(offset) {
            const index = root.buttonIndex;
            const toggleList = Config.options.sidebar.quickToggles.android.toggles;
            const buttonType = root.buttonData.type;
            const targetIndex = index + offset;
            if (!toggleList.find(toggle => toggle.type === buttonType)) return;
            if (targetIndex < 0 || targetIndex >= toggleList.length) return;
            const temp = toggleList[index];
            toggleList[index] = toggleList[targetIndex];
            toggleList[targetIndex] = temp;
        }

        onReleased: (event) => {
            if (event.button === Qt.LeftButton) toggleEnabled();
        }
        onPressed: (event) => {
            if (event.button === Qt.RightButton) toggleSize();
        }
        onPressAndHold: toggleSize()
        onWheel: (event) => {
            if (event.angleDelta.y < 0) movePositionBy(1);
            else if (event.angleDelta.y > 0) movePositionBy(-1);
            event.accepted = true;
        }
    }

    M3.Tooltip {
        extraVisibleCondition: root.tooltipText !== "" && (controlLoader.item?.hovered ?? false)
        text: root.tooltipText
    }
}
