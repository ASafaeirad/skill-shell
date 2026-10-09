import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.common.m3 as M3

Rectangle {
    id: root

    required property var directory
    property bool showBreadcrumb: true
    property real padding: Appearance.spacing.s

    signal navigateToDirectory(string path)

    function focusBreadcrumb() {
        root.showBreadcrumb = false;
        addressInput.forceActiveFocus();
    }

    onShowBreadcrumbChanged: addressInput.text = root.directory
    implicitWidth: mainLayout.implicitWidth + padding * 2
    implicitHeight: mainLayout.implicitHeight + padding * 2
    color: Appearance.colors.colLayer2

    RowLayout {
        id: mainLayout
        spacing: Appearance.spacing.s
        anchors.fill: parent
        anchors.margins: root.padding

        M3.IconButton {
            materialIcon: "drive_folder_upload"
            tooltip: "Go to parent directory"
            onClicked: root.navigateToDirectory(FileUtils.parentDirectory(root.directory))
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            implicitHeight: Appearance.sizes.m3ButtonHeight

            M3.SearchBar {
                id: addressInput
                visible: !root.showBreadcrumb
                anchors.fill: parent
                compact: true
                text: root.directory
                placeholderText: "Directory"
                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        root.navigateToDirectory(text);
                        root.showBreadcrumb = true;
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Escape) {
                        root.showBreadcrumb = true;
                        event.accepted = true;
                    }
                }
            }

            Loader {
                active: root.showBreadcrumb
                visible: root.showBreadcrumb
                anchors.fill: parent
                sourceComponent: AddressBreadcrumb {
                    directory: root.directory
                    onNavigateToDirectory: dir => root.navigateToDirectory(dir)
                }
            }
        }

        M3.IconButton {
            materialIcon: "edit"
            tooltip: "Edit directory"
            toggleable: true
            selected: !root.showBreadcrumb
            onClicked: {
                if (root.showBreadcrumb) root.focusBreadcrumb();
                else root.showBreadcrumb = true;
            }
        }
    }
}
