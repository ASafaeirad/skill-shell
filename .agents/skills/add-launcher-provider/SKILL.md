---
name: add-launcher-provider
description: Add a new search provider/prefix to the launcher (overview search), e.g. "make @f search files". NOT needed for simple launcher actions - executable scripts dropped in ~/.config/skill-shell/actions/ auto-appear under the / prefix with zero code.
---

# Add a launcher search provider

The launcher is the search box in the **overview** panel (`qs -c skill ipc call search toggle`). Existing prefixes: `>` apps, `/` actions, `;` clipboard, `:` emoji.

**First check the zero-code path:** if the request is "run X with my query" (no result list needed), it's a user action — an executable in `~/.config/skill-shell/actions/` (auto-loaded, remaining query passed as space-split args). Stop here if that fits.

Otherwise, all launcher prefixes are defined in **one table** in `modules/common/functions/SearchPrefixes.qml`.

## Adding a prefix

Add a single record to the `prefixes` array in `modules/common/functions/SearchPrefixes.qml`:

```qml
{
    character: "@",
    prefix: "@",
    kind: SearchPrefixes.PrefixKind.MyThing, // add to enum PrefixKind if desired
    icon: "my_icon",                         // Material Symbols icon name
    shape: MaterialShape.Shape.Pill,         // MaterialShape
    provider: (query, resultComp, ctx) => {
        const make = (props) => (resultComp ? resultComp.createObject(null, props) : root.createResult(props));
        const searchString = root.strip(query);
        // Return list of resultComp items
        return MyService.fuzzyQuery(searchString).map(entry => {
            return make({
                name: entry.name,
                type: "MyThing",
                verb: "Open",
                iconName: "my_icon",
                iconType: LauncherSearchResult.IconType.Material,
                execute: () => {
                    // Action to execute
                }
            });
        });
    }
}
```

Model fields: `modules/common/models/LauncherSearchResult.qml` (extend it if you need new fields, then handle rendering in `modules/widgets/overview/SearchItem.qml`).

## Verify

```sh
qs -c skill log -t 30                    # no QML errors after reload
qs -c skill ipc call search toggle       # open launcher
```
Type the new prefix + a query; confirm results, the prefix icon in the bar, and that highlight/activation work. Close with `qs -c skill ipc call search close`. Full loop: `verify-shell` skill.
