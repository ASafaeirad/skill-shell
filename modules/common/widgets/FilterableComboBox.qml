pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

StyledComboBox {
    id: root

    property var sourceModel: []
    property var selectedValue
    property string filterText: ""
    property string filterPlaceholderText: "Filter options"
    property string noResultsText: "No matching options"
    property real popupMaxHeight: Appearance.sizes.searchWidth

    readonly property var filteredModel: {
        const needle = root.normalized(root.filterText);
        const items = root.sourceItems();
        if (needle.length === 0)
            return items;
        return items.filter(item => root.normalized(root.labelFor(item)).includes(needle));
    }

    signal valueActivated(var value)

    function sourceItems() {
        const items = [];
        if (!root.sourceModel)
            return items;
        const count = root.sourceModel.length ?? root.sourceModel.count ?? 0;
        for (let index = 0; index < count; index++) {
            const item = typeof root.sourceModel.get === "function" ? root.sourceModel.get(index) : root.sourceModel[index];
            items.push(item);
        }
        return items;
    }

    function labelFor(item) {
        if (item === undefined || item === null)
            return "";
        if (typeof item !== "object")
            return String(item);
        if (root.textRole.length > 0)
            return String(item[root.textRole] ?? "");
        return String(item.display ?? item.label ?? item.value ?? "");
    }

    function valueFor(item) {
        if (item === undefined || item === null)
            return undefined;
        if (root.valueRole.length > 0 && typeof item === "object")
            return item[root.valueRole];
        return item;
    }

    function normalized(value) {
        return String(value ?? "").toLowerCase().replace(/[_/]+/g, " ").trim();
    }

    function activateFilteredIndex(index) {
        if (index < 0 || index >= root.filteredModel.length)
            return;
        root.valueActivated(root.valueFor(root.filteredModel[index]));
        root.popup.close();
    }

    model: sourceModel
    currentIndex: {
        const items = root.sourceItems();
        for (let index = 0; index < items.length; index++) {
            if (root.valueFor(items[index]) === root.selectedValue)
                return index;
        }
        return -1;
    }
    onActivated: index => root.valueActivated(root.valueFor(root.sourceItems()[index]))

    popup: Popup {
        id: popup

        y: root.height + Appearance.spacing.xxs
        width: root.width
        height: Math.min(popupContent.implicitHeight + topPadding + bottomPadding, root.popupMaxHeight)
        padding: Appearance.spacing.s
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent

        onOpened: {
            root.filterText = "";
            filterField.forceActiveFocus();
        }
        onClosed: root.filterText = ""

        enter: Transition {
            PropertyAnimation {
                properties: "opacity"
                to: 1
                duration: Appearance.animation.elementMoveFast.duration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
            }
        }

        exit: Transition {
            PropertyAnimation {
                properties: "opacity"
                to: 0
                duration: Appearance.animation.elementMoveFast.duration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
            }
        }

        background: Item {
            StyledRectangularShadow {
                target: popupBackground
            }

            Rectangle {
                id: popupBackground
                anchors.fill: parent
                radius: Appearance.rounding.normal
                color: Appearance.m3colors.m3surfaceContainerHigh
            }
        }

        contentItem: ColumnLayout {
            id: popupContent

            spacing: Appearance.spacing.s

            MaterialTextField {
                id: filterField

                Layout.fillWidth: true
                placeholderText: root.filterPlaceholderText
                text: root.filterText
                onTextEdited: root.filterText = text
                Keys.onReturnPressed: root.activateFilteredIndex(0)
                Keys.onEscapePressed: popup.close()
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                implicitHeight: root.filteredModel.length > 0 ? listView.contentHeight : noResults.implicitHeight + Appearance.spacing.m

                StyledListView {
                    id: listView

                    anchors.fill: parent
                    clip: true
                    model: popup.visible ? root.filteredModel : []
                    spacing: Appearance.spacing.xxs

                    delegate: ItemDelegate {
                        id: optionDelegate

                        required property var modelData
                        required property int index

                        readonly property bool selected: root.valueFor(modelData) === root.selectedValue

                        width: ListView.view?.width ?? root.width
                        implicitHeight: root.implicitHeight
                        onClicked: root.activateFilteredIndex(index)

                        background: Rectangle {
                            anchors.fill: parent
                            radius: Appearance.rounding.small
                            color: {
                                if (optionDelegate.selected) {
                                    if (optionDelegate.down)
                                        return Appearance.colors.colSecondaryContainerActive;
                                    if (optionDelegate.hovered)
                                        return Appearance.colors.colSecondaryContainerHover;
                                    return Appearance.colors.colSecondaryContainer;
                                }
                                if (optionDelegate.down)
                                    return Appearance.colors.colLayer3Active;
                                if (optionDelegate.hovered)
                                    return Appearance.colors.colLayer3Hover;
                                return ColorUtils.transparentize(Appearance.colors.colLayer3);
                            }

                            Behavior on color {
                                animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                            }

                            MouseArea {
                                anchors.fill: parent
                                acceptedButtons: Qt.NoButton
                                cursorShape: Qt.PointingHandCursor
                            }
                        }

                        contentItem: RowLayout {
                            spacing: Appearance.spacing.s

                            Loader {
                                Layout.alignment: Qt.AlignVCenter
                                active: typeof optionDelegate.modelData === "object" && optionDelegate.modelData?.icon?.length > 0
                                visible: active
                                sourceComponent: MaterialSymbol {
                                    text: optionDelegate.modelData?.icon ?? ""
                                    iconSize: Appearance.font.pixelSize.larger
                                    color: optionDelegate.selected ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnLayer3
                                }
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: root.labelFor(optionDelegate.modelData)
                                color: optionDelegate.selected ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnLayer3
                                elide: Text.ElideRight
                                verticalAlignment: Text.AlignVCenter
                            }
                        }
                    }
                }

                StyledText {
                    id: noResults

                    visible: root.filteredModel.length === 0
                    anchors.centerIn: parent
                    text: root.noResultsText
                    color: Appearance.colors.colSubtext
                    font.pixelSize: Appearance.font.pixelSize.small
                }
            }
        }
    }
}
