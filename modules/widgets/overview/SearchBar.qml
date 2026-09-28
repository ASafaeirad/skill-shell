pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.common.m3 as M3

RowLayout {
    id: root
    spacing: 6
    property bool animateWidth: false
    property alias searchInput: searchInput
    property string searchingText

    function forceFocus() {
        searchInput.forceActiveFocus();
    }

    property var searchPrefixType: SearchPrefixes.detect(root.searchingText)
    
    MaterialShapeWrappedMaterialSymbol {
        id: searchIcon
        Layout.alignment: Qt.AlignVCenter
        iconSize: Appearance.font.pixelSize.huge
        shape: SearchPrefixes.shape(root.searchPrefixType)
        text: SearchPrefixes.icon(root.searchPrefixType)
    }
    M3.SearchBar { // Search box
        id: searchInput
        Layout.topMargin: 4
        Layout.bottomMargin: 4
        compact: true
        focus: GlobalStates.search?.opened ?? false
        placeholderText: "Search apps and actions"
        implicitWidth: root.searchingText == "" ? Appearance.sizes.searchWidthCollapsed : Appearance.sizes.searchWidth

        Behavior on implicitWidth {
            id: searchWidthBehavior
            enabled: root.animateWidth
            NumberAnimation {
                duration: 300
                easing.type: Appearance.animation.elementMove.type
                easing.bezierCurve: Appearance.animation.elementMove.bezierCurve
            }
        }

        onTextChanged: LauncherSearch.query = text

        onAccepted: {
            if (appResults.count > 0) {
                // Get the first visible delegate and trigger its click
                let firstItem = appResults.itemAtIndex(0);
                if (firstItem && firstItem.clicked) {
                    firstItem.clicked();
                }
            }
        }

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Tab) {
                if (LauncherSearch.results.length === 0) return;
                const tabbedText = LauncherSearch.results[0].name;
                LauncherSearch.query = tabbedText;
                searchInput.text = tabbedText;
                event.accepted = true;
            }
        }
    }

    M3.IconButton {
        Layout.topMargin: 4
        Layout.bottomMargin: 4
        Layout.rightMargin: 4
        materialIcon: "image_search"
        tooltip: "Google Lens"
        onClicked: {
            GlobalStates.search?.close();
            GlobalStates.regionSearchRequested();
        }
    }
}
