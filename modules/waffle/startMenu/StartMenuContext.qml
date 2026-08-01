import QtQuick
import Quickshell
import Quickshell.Io
import qs
import qs.modules.common
import qs.modules.common.functions
import qs.services

Scope {
    id: root

    signal accepted

    property int currentIndex: 0
    function setCurrentIndex(index) {
        if (index == currentIndex)
            return;
        currentIndex = index;
    }

    function selectCategory(category) {
        for (let i = 0; i < root.categories.length; i++) {
            const thisCategoryName = root.categories[i].name;
            if (thisCategoryName.startsWith(category) || category.startsWith(thisCategoryName)) {
                LauncherSearch.query = SearchPrefixes.ensurePrefix(LauncherSearch.query, root.categories[i].kind);
                return;
            }
        }
    }
    property list<var> categories: SearchPrefixes.kinds.map(kind => ({
        kind: kind,
        name: SearchPrefixes.displayName(kind),
        prefix: SearchPrefixes.prefix(kind)
    }))

}
