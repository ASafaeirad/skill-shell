pragma Singleton

import QtQuick
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.models
import qs.modules.common.functions

QtObject {
    id: root

    enum PrefixKind {
        DefaultSearch,
        Action,
        App,
        Clipboard,
        Emojis
    }

    readonly property var defaultRecord: ({
        character: "",
        prefix: "",
        kind: SearchPrefixes.PrefixKind.DefaultSearch,
        icon: "search",
        shape: MaterialShape.Shape.Cookie7Sided,
        provider: null
    })

    readonly property var prefixes: [
        {
            character: "/",
            prefix: "/",
            kind: SearchPrefixes.PrefixKind.Action,
            icon: "settings_suggest",
            shape: MaterialShape.Shape.Pill,
            provider: (query, resultComp, ctx) => {
                const make = (props) => (resultComp ? resultComp.createObject(null, props) : root.createResult(props));
                const allActions = ctx?.allActions ?? LauncherSearch.allActions;
                const actionPrefix = root.prefix(SearchPrefixes.PrefixKind.Action);
                return allActions.map(action => {
                    const actionString = `${actionPrefix}${action.action}`;
                    if (actionString.startsWith(query) || query.startsWith(actionString)) {
                        return make({
                            name: query.startsWith(actionString) ? query : actionString,
                            verb: "Run",
                            type: "Action",
                            iconName: 'settings_suggest',
                            iconType: LauncherSearchResult.IconType.Material,
                            execute: () => {
                                action.execute(query.split(" ").slice(1).join(" "));
                            }
                        });
                    }
                    return null;
                }).filter(Boolean);
            }
        },
        {
            character: ">",
            prefix: ">",
            kind: SearchPrefixes.PrefixKind.App,
            icon: "apps",
            shape: MaterialShape.Shape.Clover4Leaf,
            provider: (query, resultComp, ctx) => {
                const make = (props) => (resultComp ? resultComp.createObject(null, props) : root.createResult(props));
                const appQuery = root.strip(query, SearchPrefixes.PrefixKind.App);
                return AppSearch.fuzzyQuery(appQuery).map(entry => {
                    return make({
                        type: "App",
                        id: entry.id,
                        name: entry.name,
                        iconName: entry.icon,
                        iconType: LauncherSearchResult.IconType.System,
                        verb: "Open",
                        execute: () => {
                            if (!entry.runInTerminal)
                                entry.execute();
                            else {
                                Quickshell.execDetached(["bash", '-c', `${Apps.terminal} -e '${StringUtils.shellSingleQuoteEscape(entry.command.join(' '))}'`]);
                            }
                        },
                        comment: entry.comment,
                        runInTerminal: entry.runInTerminal,
                        genericName: entry.genericName,
                        keywords: entry.keywords,
                        actions: entry.actions.map(action => {
                            return make({
                                name: action.name,
                                iconName: action.icon,
                                iconType: LauncherSearchResult.IconType.System,
                                execute: () => {
                                    if (!action.runInTerminal)
                                        action.execute();
                                    else {
                                        Quickshell.execDetached(["bash", '-c', `${Apps.terminal} -e '${StringUtils.shellSingleQuoteEscape(action.command.join(' '))}'`]);
                                    }
                                }
                            });
                        })
                    });
                });
            }
        },
        {
            character: ";",
            prefix: ";",
            kind: SearchPrefixes.PrefixKind.Clipboard,
            icon: "content_paste_search",
            shape: MaterialShape.Shape.Gem,
            provider: (query, resultComp, ctx) => {
                const make = (props) => (resultComp ? resultComp.createObject(null, props) : root.createResult(props));
                const searchString = root.strip(query, SearchPrefixes.PrefixKind.Clipboard);
                return Cliphist.fuzzyQuery(searchString).map(entry => {
                    const type = `#${entry.match(/^\s*(\S+)/)?.[1] || ""}`;
                    return make({
                        rawValue: entry,
                        name: StringUtils.cleanCliphistEntry(entry),
                        verb: "",
                        type: type,
                        execute: () => {
                            Cliphist.copy(entry);
                        },
                        actions: [make({
                                name: "Copy",
                                iconName: "content_copy",
                                iconType: LauncherSearchResult.IconType.Material,
                                execute: () => {
                                    Cliphist.copy(entry);
                                }
                            }), make({
                                name: "Delete",
                                iconName: "delete",
                                iconType: LauncherSearchResult.IconType.Material,
                                execute: () => {
                                    Cliphist.deleteEntry(entry);
                                }
                            })]
                    });
                }).filter(Boolean);
            }
        },
        {
            character: ":",
            prefix: ":",
            kind: SearchPrefixes.PrefixKind.Emojis,
            icon: "add_reaction",
            shape: MaterialShape.Shape.Sunny,
            provider: (query, resultComp, ctx) => {
                const make = (props) => (resultComp ? resultComp.createObject(null, props) : root.createResult(props));
                const searchString = root.strip(query, SearchPrefixes.PrefixKind.Emojis);
                return Emojis.fuzzyQuery(searchString).map(entry => {
                    const emoji = entry.match(/^\s*(\S+)/)?.[1] || "";
                    return make({
                        rawValue: entry,
                        name: entry.replace(/^\s*\S+\s+/, ""),
                        iconName: emoji,
                        iconType: LauncherSearchResult.IconType.Text,
                        verb: "Copy",
                        type: "Emoji",
                        execute: () => {
                            Quickshell.clipboardText = entry.match(/^\s*(\S+)/)?.[1];
                        }
                    });
                }).filter(Boolean);
            }
        }
    ]

    readonly property string action: prefix(SearchPrefixes.PrefixKind.Action)
    readonly property string app: prefix(SearchPrefixes.PrefixKind.App)
    readonly property string clipboard: prefix(SearchPrefixes.PrefixKind.Clipboard)
    readonly property string emojis: prefix(SearchPrefixes.PrefixKind.Emojis)

    property Component resultComp: Component {
        LauncherSearchResult {}
    }

    function createResult(props) {
        return resultComp.createObject(null, props);
    }

    function getRecordForQuery(query) {
        if (!query) return null;
        return prefixes.find(r => query.startsWith(r.character || r.prefix)) ?? null;
    }

    function getRecord(kind) {
        if (typeof kind === "object" && kind !== null) return kind;
        return prefixes.find(r => r.kind === kind) ?? defaultRecord;
    }

    function record(kindOrQuery) {
        if (typeof kindOrQuery === "string") return getRecordForQuery(kindOrQuery);
        return getRecord(kindOrQuery);
    }

    function detect(query) {
        const rec = getRecordForQuery(query);
        return rec ? rec.kind : SearchPrefixes.PrefixKind.DefaultSearch;
    }

    function prefix(kind) {
        const rec = getRecord(kind);
        return rec ? (rec.character || rec.prefix || "") : "";
    }

    function strip(query, expectedKind) {
        if (!query) return "";
        const detectedKind = detect(query);
        if (expectedKind !== undefined && detectedKind !== expectedKind)
            return query;
        const detectedPrefix = prefix(detectedKind);
        return detectedPrefix === "" ? query : query.slice(detectedPrefix.length);
    }

    function icon(kind) {
        const rec = getRecord(kind);
        return rec ? rec.icon : defaultRecord.icon;
    }

    function shape(kind) {
        const rec = getRecord(kind);
        return rec ? rec.shape : defaultRecord.shape;
    }
}
