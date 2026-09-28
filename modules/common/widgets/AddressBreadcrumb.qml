import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.common.m3 as M3
import qs.services

ListView {
    id: root

    required property var directory
    property var breadcrumbDirectory: ""

    signal navigateToDirectory(string path)

    Component.onCompleted: breadcrumbDirectory = directory
    onDirectoryChanged: {
        if (breadcrumbDirectory.startsWith(directory))
            return ;

        breadcrumbDirectory = directory;
    }
    orientation: ListView.Horizontal
    clip: true
    spacing: 2
    model: breadcrumbDirectory.split("/")

    delegate: M3.Button {
        id: folderButton
        variant: "outlined"
        toggleable: true

        required property var modelData
        required property int index

        text: index === 0 ? "/" : modelData
        selected: {
            if (directory.trim() === "/")
                return index === 0;

            return index === directory.split("/").length - 1;
        }
        onClicked: {
            root.navigateToDirectory(breadcrumbDirectory.split("/").slice(0, index + 1).join("/"));
        }
    }

}
