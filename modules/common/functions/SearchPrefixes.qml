pragma Singleton

import QtQuick
import qs.modules.common.widgets

QtObject {
    enum PrefixKind {
        DefaultSearch,
        Action,
        App,
        Clipboard,
        Emojis,
        Math,
        ShellCommand,
        WebSearch
    }

    readonly property string action: "/"
    readonly property string app: ">"
    readonly property string clipboard: ";"
    readonly property string emojis: ":"
    readonly property string math: "="
    readonly property string shellCommand: "$"
    readonly property string webSearch: "?"
    readonly property bool showDefaultActionsWithoutPrefix: true

    // Canonical order used by the waffle search category chips.
    readonly property list<int> kinds: [
        SearchPrefixes.PrefixKind.DefaultSearch,
        SearchPrefixes.PrefixKind.App,
        SearchPrefixes.PrefixKind.Action,
        SearchPrefixes.PrefixKind.Clipboard,
        SearchPrefixes.PrefixKind.Emojis,
        SearchPrefixes.PrefixKind.Math,
        SearchPrefixes.PrefixKind.ShellCommand,
        SearchPrefixes.PrefixKind.WebSearch
    ]

    function detect(query) {
        if (query.startsWith(action)) return SearchPrefixes.PrefixKind.Action;
        if (query.startsWith(app)) return SearchPrefixes.PrefixKind.App;
        if (query.startsWith(clipboard)) return SearchPrefixes.PrefixKind.Clipboard;
        if (query.startsWith(emojis)) return SearchPrefixes.PrefixKind.Emojis;
        if (query.startsWith(math)) return SearchPrefixes.PrefixKind.Math;
        if (query.startsWith(shellCommand)) return SearchPrefixes.PrefixKind.ShellCommand;
        if (query.startsWith(webSearch)) return SearchPrefixes.PrefixKind.WebSearch;
        return SearchPrefixes.PrefixKind.DefaultSearch;
    }

    function prefix(kind) {
        switch (kind) {
        case SearchPrefixes.PrefixKind.Action: return action;
        case SearchPrefixes.PrefixKind.App: return app;
        case SearchPrefixes.PrefixKind.Clipboard: return clipboard;
        case SearchPrefixes.PrefixKind.Emojis: return emojis;
        case SearchPrefixes.PrefixKind.Math: return math;
        case SearchPrefixes.PrefixKind.ShellCommand: return shellCommand;
        case SearchPrefixes.PrefixKind.WebSearch: return webSearch;
        default: return "";
        }
    }

    function strip(query, expectedKind) {
        const detectedKind = detect(query);
        if (expectedKind !== undefined && detectedKind !== expectedKind)
            return query;
        const detectedPrefix = prefix(detectedKind);
        return detectedPrefix === "" ? query : query.slice(detectedPrefix.length);
    }

    function ensurePrefix(query, kind) {
        const requestedPrefix = prefix(kind);
        const currentPrefix = prefix(detect(query));
        return requestedPrefix + (currentPrefix === "" ? query : query.slice(currentPrefix.length));
    }

    function displayName(kind) {
        switch (kind) {
        case SearchPrefixes.PrefixKind.Action: return "Actions";
        case SearchPrefixes.PrefixKind.App: return "Apps";
        case SearchPrefixes.PrefixKind.Clipboard: return "Clipboard";
        case SearchPrefixes.PrefixKind.Emojis: return "Emojis";
        case SearchPrefixes.PrefixKind.Math: return "Math";
        case SearchPrefixes.PrefixKind.ShellCommand: return "Commands";
        case SearchPrefixes.PrefixKind.WebSearch: return "Web";
        default: return "All";
        }
    }

    function icon(kind) {
        switch (kind) {
        case SearchPrefixes.PrefixKind.Action: return "settings_suggest";
        case SearchPrefixes.PrefixKind.App: return "apps";
        case SearchPrefixes.PrefixKind.Clipboard: return "content_paste_search";
        case SearchPrefixes.PrefixKind.Emojis: return "add_reaction";
        case SearchPrefixes.PrefixKind.Math: return "calculate";
        case SearchPrefixes.PrefixKind.ShellCommand: return "terminal";
        case SearchPrefixes.PrefixKind.WebSearch: return "travel_explore";
        default: return "search";
        }
    }

    function shape(kind) {
        switch (kind) {
        case SearchPrefixes.PrefixKind.Action: return MaterialShape.Shape.Pill;
        case SearchPrefixes.PrefixKind.App: return MaterialShape.Shape.Clover4Leaf;
        case SearchPrefixes.PrefixKind.Clipboard: return MaterialShape.Shape.Gem;
        case SearchPrefixes.PrefixKind.Emojis: return MaterialShape.Shape.Sunny;
        case SearchPrefixes.PrefixKind.Math: return MaterialShape.Shape.PuffyDiamond;
        case SearchPrefixes.PrefixKind.ShellCommand: return MaterialShape.Shape.PixelCircle;
        case SearchPrefixes.PrefixKind.WebSearch: return MaterialShape.Shape.SoftBurst;
        default: return MaterialShape.Shape.Cookie7Sided;
        }
    }
}
