---
name: add-launcher-provider
description: Add a new search provider/prefix to the launcher (overview search), e.g. "make @f search files". NOT needed for simple launcher actions - executable scripts dropped in ~/.config/illogical-impulse/actions/ auto-appear under the / prefix with zero code.
---

# Add a launcher search provider

The launcher is the search box in the **overview** panel (`qs -c ii ipc call search toggle`). Existing prefixes: `>` apps, `/` actions, `;` clipboard, `:` emoji, `=` math, `$` shell, `?` web.

**First check the zero-code path:** if the request is "run X with my query" (no result list needed), it's a user action — an executable in `~/.config/illogical-impulse/actions/` (auto-loaded, remaining query passed as space-split args). Stop here if that fits.

Otherwise, prefix logic is **duplicated across many files** — work through this checklist completely; a missed site means inconsistent UI, not a crash.

## Checklist

1. **Prefix string** — `modules/common/Config.qml`, `search.prefix` JsonObject (~line 482): add `property string myThing: "@"`.

2. **Result provider** — `services/LauncherSearch.qml`:
   - Add your prefix to the array in `ensurePrefix()` (~line 18).
   - Add a branch in the `results` binding chain (~lines 174–357): `if (root.query.startsWith(Config.options.search.prefix.myThing)) { ... }`, strip with `StringUtils.cleanPrefix(root.query, ...)`, build results via `resultComp.createObject(null, {...})` following the clipboard/emoji branches. Model fields: `modules/common/models/LauncherSearchResult.qml` (extend it if you need new fields, then handle rendering in `modules/ii/overview/SearchItem.qml`).
   - Heavy/async sources: debounce like math does (`nonAppResultDelay`, default 30 ms), don't block the binding.
   - Fuzzy matching: put a `fuzzyQuery(search)` in a new `services/MyThing.qml` singleton using `Fuzzy.go(search, preparedEntries, { all: true, key: "name" })` — copy `AppSearch.qml`/`Emojis.qml`. Pre-`Fuzzy.prepare()` entries once, not per keystroke.

3. **Search bar icon** — `modules/ii/overview/SearchBar.qml`: extend the `SearchPrefixType` enum, the `searchingText.startsWith(...)` chain (~line 25), and both `switch`es (MaterialShape ~line 40, icon name ~line 50 — Material Symbols name).

4. **Prefix stripping in the widget** — `modules/ii/overview/SearchWidget.qml` ~line 215: add `Config.options.search.prefix.myThing` to the `cleanOnePrefix([...])` array.

5. **Waffle parity — conscious decision, usually skip.** The waffle family duplicates prefix handling in `modules/waffle/startMenu/StartMenuContext.qml`, `startMenu/searchPage/TagStrip.qml`, `startMenu/WaffleStartMenu.qml`. The user runs the `ii` family; state explicitly that waffle was not updated unless asked.

## Verify

```sh
qs -c ii log -t 30                    # no QML errors after reload
qs -c ii ipc call search toggle       # open launcher
```
Type the new prefix + a query; confirm results, the prefix icon in the bar, and that highlight/activation work. Close with `qs -c ii ipc call search close`. Full loop: `verify-shell` skill.
