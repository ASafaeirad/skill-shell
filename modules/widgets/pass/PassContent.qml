pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

OverlayDialogCard {
    id: root

    signal closeRequested

    property string query: searchField.text
    property bool showIgnored: false
    readonly property var ignoredEntryPatterns: Config.options.pass.ignoredEntryPatterns
    property var filteredEntries: PassService.fuzzyQuery(query, showIgnored, ignoredEntryPatterns)
    property var currentEntry: listView.currentIndex >= 0 && listView.currentIndex < filteredEntries.length
                               ? filteredEntries[listView.currentIndex] : null
    property bool detailsOpen: false
    property var detailEntry: null
    readonly property real lineWidth: Appearance.sizes.elevationMargin / 10
    readonly property color mildBorderColor: ColorUtils.mix(Appearance.colors.colOutline,
                                                            Appearance.colors.colLayer1, 0.45)
    readonly property real entryHeight: Appearance.sizes.barHeight + Appearance.spacing.lg
    readonly property real groupHeight: Appearance.sizes.barHeight + Appearance.spacing.s

    component Hint: Row {
        id: hint
        required property string keys
        required property string label
        spacing: Appearance.spacing.s

        KeyboardKey {
            anchors.verticalCenter: parent.verticalCenter
            key: hint.keys
        }
        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            text: hint.label
            color: Appearance.colors.colSubtext
            font.pixelSize: Appearance.font.pixelSize.smaller
        }
    }

    function selectRelative(delta) {
        if (filteredEntries.length === 0)
            return;
        listView.currentIndex = Math.max(0, Math.min(listView.currentIndex + delta, filteredEntries.length
                                                     - 1));
        listView.positionViewAtIndex(listView.currentIndex, ListView.Contain);
    }

    function activate(action) {
        const entry = detailsOpen ? detailEntry : currentEntry;
        if (!entry)
            return;
        PassService.requestAction(action, entry.name);
    }

    function openDetails() {
        if (!currentEntry)
            return;
        detailEntry = currentEntry;
        detailsOpen = true;
        detailsFlickable.contentY = 0;
        PassService.loadEntry(detailEntry.name);
        root.forceActiveFocus();
    }

    function closeDetails() {
        detailsOpen = false;
        detailEntry = null;
        PassService.clearSecrets();
        searchField.forceActiveFocus();
    }

    function handleKey(event) {
        const control = event.modifiers & Qt.ControlModifier;
        if (control && event.key === Qt.Key_I) {
            showIgnored = !showIgnored;
            PassService.showStatus(showIgnored ? "Ignored entries shown" : "Ignored entries hidden");
            event.accepted = true;
            return;
        }
        if (detailsOpen) {
            if (event.key === Qt.Key_Escape || event.key === Qt.Key_Left || (control && event.key
                                                                             === Qt.Key_H)) {
                root.closeDetails();
            } else if (control && event.key === Qt.Key_O) {
                root.activate("otp");
            } else if (control && event.key === Qt.Key_U) {
                root.activate("autotype");
            } else if (control && event.key === Qt.Key_R) {
                root.activate("reveal");
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                root.activate("copy");
            } else {
                event.accepted = false;
                return;
            }
            event.accepted = true;
            return;
        }
        if (event.key === Qt.Key_Escape) {
            if (searchField.text.length > 0)
                searchField.text = "";
            else
                root.closeRequested();
        } else if (event.key === Qt.Key_Down || (control && event.key === Qt.Key_J)) {
            root.selectRelative(1);
        } else if (event.key === Qt.Key_Up || (control && event.key === Qt.Key_K)) {
            root.selectRelative(-1);
        } else if (control && event.key === Qt.Key_O) {
            root.activate("otp");
        } else if (event.key === Qt.Key_Right || (control && event.key === Qt.Key_L)) {
            root.openDetails();
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            root.activate("copy");
        } else {
            event.accepted = false;
            return;
        }
        event.accepted = true;
    }

    function showGroupHeader(index) {
        if (index === 0)
            return true;
        return filteredEntries[index - 1].topGroup !== filteredEntries[index].topGroup;
    }

    function fieldValue(key) {
        const wanted = key.toLowerCase();
        const match = PassService.fields.find(field => field.key.toLowerCase() === wanted);
        return match?.value ?? "";
    }

    function friendlyAge(timestamp) {
        const seconds = Math.max(0, Math.floor((Date.now() - timestamp) / 1000));
        if (seconds < 60)
            return "just now";
        const minutes = Math.floor(seconds / 60);
        if (minutes < 60)
            return `${minutes} minutes ago`;
        const hours = Math.floor(minutes / 60);
        if (hours < 24)
            return `${hours} hours ago`;
        const days = Math.floor(hours / 24);
        if (days < 30)
            return `${days} days ago`;
        return Qt.formatDate(new Date(timestamp), "MMM d, yyyy");
    }

    implicitWidth: Appearance.sizes.sidebarWidthExtended
    implicitHeight: Appearance.sizes.wallpaperSelectorHeight + Appearance.sizes.barHeight * 3
    focus: detailsOpen
    Keys.onPressed: event => root.handleKey(event)

    Component.onCompleted: {
        searchField.forceActiveFocus();
        PassService.refresh();
        animateIn();
    }
    onAboutToAnimateIn: {
        detailsOpen = false;
        detailEntry = null;
        showIgnored = false;
        searchField.text = "";
        searchField.forceActiveFocus();
    }
    onFilteredEntriesChanged: {
        listView.currentIndex = filteredEntries.length > 0 ? 0 : -1;
    }

    Connections {
        target: PassService
        function onFieldsChanged() {
            Qt.callLater(() => detailsFlickable.contentY = 0);
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: Appearance.sizes.barHeight * 2
            color: Appearance.colors.colLayer1
            topLeftRadius: Appearance.rounding.large
            topRightRadius: Appearance.rounding.large

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Appearance.spacing.xl
                anchors.rightMargin: Appearance.spacing.xl
                spacing: Appearance.spacing.lg

                IconToolbarButton {
                    visible: root.detailsOpen
                    Layout.preferredWidth: Appearance.sizes.barHeight
                    Layout.preferredHeight: Appearance.sizes.barHeight
                    text: "arrow_back"
                    onClicked: root.closeDetails()
                }

                MaterialSymbol {
                    visible: !root.detailsOpen
                    text: "password"
                    iconSize: Appearance.font.pixelSize.hugeass
                    color: Appearance.colors.colOnSurface
                }

                Item {
                    visible: !root.detailsOpen
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    StyledText {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        visible: searchField.text.length === 0
                        text: "Search pass store…"
                        font.pixelSize: Appearance.font.pixelSize.huge
                        font.weight: Font.Medium
                        color: Appearance.colors.colSubtext
                    }

                    StyledTextInput {
                        id: searchField
                        anchors.fill: parent
                        verticalAlignment: TextInput.AlignVCenter
                        focus: true
                        font.pixelSize: Appearance.font.pixelSize.huge
                        font.weight: Font.Medium
                        font.family: Appearance.font.family.main
                        Keys.onPressed: event => root.handleKey(event)
                    }

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.NoButton
                        hoverEnabled: true
                        cursorShape: Qt.IBeamCursor
                    }
                }

                ColumnLayout {
                    visible: root.detailsOpen
                    Layout.fillWidth: true
                    spacing: 0

                    StyledText {
                        Layout.fillWidth: true
                        text: root.detailEntry?.relativeName ?? ""
                        font.pixelSize: Appearance.font.pixelSize.huge
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnSurface
                        elide: Text.ElideRight
                    }
                    StyledText {
                        Layout.fillWidth: true
                        text: "Password details"
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colSubtext
                    }
                }

                Rectangle {
                    visible: !root.detailsOpen
                    implicitWidth: countText.implicitWidth + Appearance.spacing.lg * 2
                    implicitHeight: countText.implicitHeight + Appearance.spacing.s
                    radius: Appearance.rounding.full
                    color: Appearance.colors.colLayer3

                    StyledText {
                        id: countText
                        anchors.centerIn: parent
                        font.family: Appearance.font.family.monospace
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colOnLayer3
                        text: `${root.filteredEntries.length} ${root.filteredEntries.length === 1 ? "entry" : "entries"
                                                                                                    }`

                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: root.lineWidth
            color: root.mildBorderColor
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            Item {
                visible: !root.detailsOpen
                Layout.fillWidth: true
                Layout.fillHeight: true

                StyledListView {
                    id: listView
                    anchors.fill: parent
                    anchors.leftMargin: Appearance.spacing.m
                    anchors.rightMargin: Appearance.spacing.m
                    clip: true
                    model: root.filteredEntries
                    currentIndex: -1
                    spacing: 0
                    boundsBehavior: Flickable.StopAtBounds
                    ScrollBar.vertical.policy: ScrollBar.AlwaysOn

                    delegate: Item {
                        id: entryDelegate
                        required property var modelData
                        required property int index
                        readonly property bool selected: index === listView.currentIndex
                        readonly property bool hasHeader: root.showGroupHeader(index)

                        width: listView.width
                        height: root.entryHeight + (hasHeader ? root.groupHeight : 0)

                        RowLayout {
                            visible: entryDelegate.hasHeader
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.leftMargin: Appearance.spacing.lg
                            anchors.rightMargin: Appearance.spacing.lg
                            height: root.groupHeight
                            spacing: Appearance.spacing.s

                            MaterialSymbol {
                                text: "folder"
                                iconSize: Appearance.font.pixelSize.normal
                                color: Appearance.colors.colSubtext
                            }
                            StyledText {
                                Layout.fillWidth: true
                                text: entryDelegate.modelData.topGroup.toUpperCase()
                                font.family: Appearance.font.family.monospace
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                font.letterSpacing: Appearance.sizes.elevationMargin / 10
                                color: Appearance.colors.colSubtext
                                elide: Text.ElideRight
                            }
                        }

                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            height: root.entryHeight
                            radius: Appearance.rounding.small
                            color: entryDelegate.selected ? Appearance.colors.colPrimaryContainer :
                                                            entryMouse.containsMouse
                                                            ? Appearance.colors.colLayer1Hover : "transparent"

                            Behavior on color {
                                animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(
                                               this)
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: Appearance.spacing.lg
                                anchors.rightMargin: Appearance.spacing.lg
                                spacing: Appearance.spacing.s

                                MaterialSymbol {
                                    text: entryDelegate.modelData.icon
                                    iconSize: Appearance.font.pixelSize.huge
                                    color: entryDelegate.selected ? Appearance.colors.colOnPrimaryContainer :
                                                                    Appearance.colors.colSubtext
                                }
                                StyledText {
                                    Layout.fillWidth: true
                                    text: entryDelegate.modelData.relativeName
                                    font.pixelSize: Appearance.font.pixelSize.large
                                    color: entryDelegate.selected ? Appearance.colors.colOnPrimaryContainer :
                                                                    Appearance.colors.colOnLayer0
                                    elide: Text.ElideRight
                                }
                                MaterialSymbol {
                                    visible: PassService.otpEntries[entryDelegate.modelData.name] ?? false
                                    text: "timer"
                                    iconSize: Appearance.font.pixelSize.larger
                                    color: entryDelegate.selected ? Appearance.colors.colOnPrimaryContainer :
                                                                    Appearance.colors.colTertiary
                                }
                                MaterialSymbol {
                                    text: "chevron_right"
                                    iconSize: Appearance.font.pixelSize.larger
                                    color: entryDelegate.selected ? Appearance.colors.colOnPrimaryContainer :
                                                                    Appearance.colors.colSubtext
                                }
                            }

                            MouseArea {
                                id: entryMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onEntered: {
                                    listView.currentIndex = entryDelegate.index;
                                }
                                onClicked: {
                                    listView.currentIndex = entryDelegate.index;
                                    searchField.forceActiveFocus();
                                }
                                onDoubleClicked: root.activate("copy")
                            }
                        }
                    }

                    StyledText {
                        anchors.centerIn: parent
                        visible: root.filteredEntries.length === 0
                        color: Appearance.colors.colSubtext
                        text: PassService.entries.length === 0 ? "No pass entries found" :
                                                                 "No matching entries"
                    }
                }
            }

            ColumnLayout {
                visible: root.detailsOpen
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 0

                StyledFlickable {
                    id: detailsFlickable
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    contentWidth: width
                    contentHeight: Math.max(height, detailsColumn.implicitHeight + Appearance.spacing.xl
                                            * 2)
                    boundsBehavior: Flickable.StopAtBounds
                    ScrollBar.vertical.policy: ScrollBar.AsNeeded

                    ColumnLayout {
                        id: detailsColumn
                        x: Appearance.spacing.xl
                        y: Appearance.spacing.xl
                        width: detailsFlickable.width - Appearance.spacing.xl * 2
                        spacing: Appearance.spacing.lg
                        visible: root.detailsOpen && root.detailEntry !== null

                        StyledText {
                            Layout.fillWidth: true
                            text: root.detailEntry ? `${root.detailEntry.name}.gpg` : ""
                            font.family: Appearance.font.family.monospace
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colSubtext
                            elide: Text.ElideMiddle
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: root.detailEntry?.relativeName ?? ""
                            font.pixelSize: Appearance.font.pixelSize.title
                            font.weight: Font.DemiBold
                            color: Appearance.colors.colOnLayer0
                            elide: Text.ElideRight
                        }

                        Item {
                            Layout.preferredHeight: Appearance.spacing.s
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: Appearance.sizes.barHeight * 2
                            radius: Appearance.rounding.normal
                            color: Appearance.colors.colLayer1
                            border.width: root.lineWidth
                            border.color: root.mildBorderColor

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: Appearance.spacing.lg
                                anchors.rightMargin: Appearance.spacing.lg
                                spacing: Appearance.spacing.lg

                                MaterialSymbol {
                                    text: "key"
                                    iconSize: Appearance.font.pixelSize.larger
                                    color: Appearance.colors.colOnLayer1
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: Appearance.spacing.s / 2

                                    StyledText {
                                        text: "PASSWORD"
                                        font.family: Appearance.font.family.monospace
                                        font.pixelSize: Appearance.font.pixelSize.smallest
                                        color: Appearance.colors.colSubtext
                                    }
                                    StyledText {
                                        Layout.fillWidth: true
                                        text: PassService.loading ? "Unlocking…" : PassService.revealedEntry
                                                                    === root.detailEntry?.name
                                                                    ? PassService.secret : "••••••••••••••••"
                                        font.family: Appearance.font.family.monospace
                                        font.pixelSize: Appearance.font.pixelSize.normal
                                        color: Appearance.colors.colOnLayer1
                                        elide: Text.ElideRight
                                    }
                                }

                                RowLayout {
                                    spacing: Appearance.spacing.s / 2
                                    MaterialSymbol {
                                        text: PassService.revealedEntry === root.detailEntry?.name
                                              ? "visibility_off" : "visibility"
                                        iconSize: Appearance.font.pixelSize.normal
                                        color: Appearance.colors.colSubtext
                                    }
                                    StyledText {
                                        text: "Ctrl+R"
                                        font.pixelSize: Appearance.font.pixelSize.smaller
                                        color: Appearance.colors.colSubtext
                                    }
                                }
                            }
                        }

                        Repeater {
                            model: PassService.loadedEntry === root.detailEntry?.name ? PassService.fields :
                                                                                        []
                            delegate: Rectangle {
                                required property var modelData
                                Layout.fillWidth: true
                                Layout.preferredHeight: Appearance.sizes.barHeight
                                                        + Appearance.spacing.lg
                                radius: Appearance.rounding.small
                                color: Appearance.colors.colLayer1

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: Appearance.spacing.lg
                                    anchors.rightMargin: Appearance.spacing.lg
                                    spacing: Appearance.spacing.lg

                                    StyledText {
                                        Layout.preferredWidth: Appearance.sizes.barCenterSideModuleWidth
                                        text: modelData.key.toLowerCase()
                                        font.family: Appearance.font.family.monospace
                                        font.pixelSize: Appearance.font.pixelSize.smaller
                                        color: Appearance.colors.colSubtleText
                                        elide: Text.ElideRight
                                    }
                                    StyledText {
                                        Layout.fillWidth: true
                                        text: modelData.value
                                        font.family: Appearance.font.family.monospace
                                        font.pixelSize: Appearance.font.pixelSize.normal
                                        color: Appearance.colors.colOnLayer1
                                        elide: Text.ElideRight
                                    }
                                }
                            }
                        }

                        StyledText {
                            Layout.fillWidth: true
                            visible: PassService.errorText.length > 0
                            text: PassService.errorText
                            color: Appearance.colors.colError
                            font.pixelSize: Appearance.font.pixelSize.smaller
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: root.lineWidth
            color: root.mildBorderColor
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: footerHints.implicitHeight + Appearance.spacing.lg * 2
            color: Appearance.colors.colLayer1

            Column {
                id: footerHints
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: Appearance.spacing.xl
                anchors.rightMargin: Appearance.spacing.xl
                spacing: Appearance.spacing.lg

                Row {
                    spacing: Appearance.spacing.lg
                    Hint {
                        keys: root.detailsOpen ? "←" : "↑↓"
                        label: root.detailsOpen ? "back" : "move"
                    }
                    Hint {
                        keys: "↵"
                        label: "copy password"
                    }
                    Hint {
                        keys: "^O"
                        label: "copy OTP"
                    }
                    Hint {
                        keys: root.detailsOpen ? "^U" : "^L / →"
                        label: root.detailsOpen ? "autotype" : "open details"
                    }
                }
                Row {
                    spacing: Appearance.spacing.lg
                    Hint {
                        keys: "^I"
                        label: root.showIgnored ? "hide ignored" : "show ignored"
                    }
                    Hint {
                        visible: root.detailsOpen
                        keys: "^R"
                        label: PassService.revealedEntry === root.detailEntry?.name ? "hide" : "reveal"
                    }
                    Hint {
                        visible: root.detailsOpen
                        keys: "esc"
                        label: "back"
                    }
                }
            }
        }
    }
}
