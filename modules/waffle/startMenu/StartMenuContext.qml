import QtQuick
import Quickshell
import Quickshell.Io
import qs
import qs.modules.common
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
                LauncherSearch.ensurePrefix(root.categories[i].prefix);
                return;
            }
        }
    }
    property list<var> categories: [
        {
            name: "All",
            prefix: ""
        },
        {
            name: "Apps",
            prefix: Config.options.search.prefix.app
        },
        {
            name: "Actions",
            prefix: Config.options.search.prefix.action
        },
        {
            name: "Clipboard",
            prefix: Config.options.search.prefix.clipboard
        },
        {
            name: "Emojis",
            prefix: Config.options.search.prefix.emojis
        },
        {
            name: "Math",
            prefix: Config.options.search.prefix.math
        },
        {
            name: "Commands",
            prefix: Config.options.search.prefix.shellCommand
        },
        {
            name: "Web",
            prefix: Config.options.search.prefix.webSearch
        },
    ]

}
