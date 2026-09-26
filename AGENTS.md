# Quickshell config

This is the **skill** desktop shell for Quickshell (0.3.0, Qt 6.11) on Arch Linux + Hyprland. Entry point: `shell.qml`. It runs as `qs -c skill`, autostarted by Hyprland (`exec-once = qs -c skill` in `~/.config/hypr/autostart.conf`).

The shell uses the **widgets** panel family, loaded lazily in `shell.qml`.

⚠️ **The shell owns the polkit agent and notification daemon.** Don't leave it dead; avoid killing it unless a hot reload is genuinely stuck (see Verifying changes).

## Directory map

```
.
├── shell.qml                 # ShellRoot: startup and lazy panel loading
├── settings.qml              # Separate settings app: qs -p settings.qml
├── GlobalStates.qml          # Singleton: open/closed state of every panel
├── ReloadPopup.qml           # Shows QML error popup when hot reload fails
├── services/                 # ~45 pragma Singleton backends, one per concern:
│                             #   Audio, Battery, Brightness, Network, Bluetooth,
│                             #   Cliphist, Emojis, AppSearch, LauncherSearch,
│                             #   Notifications, MprisController, HyprlandData, ...
├── modules/
│   ├── common/               # Shared: Appearance.qml (theme tokens), Config.qml
│   │   ├── widgets/          #   StyledText, RippleButton, MaterialSymbol,
│   │   │                     #   ConfigSwitch/Slider/SpinBox/SelectionArray, ...
│   │   ├── functions/        #   Fuzzy.qml (fuzzysort), StringUtils, ColorUtils
│   │   └── models/           #   LauncherSearchResult.qml etc.
│   ├── widgets/              # Panels: bar/, dock/,
│   │                         #   overview/ (= the launcher), sidebarLeft/, sidebarRight/,
│   │                         #   notificationPopup/, onScreenDisplay/, sessionScreen/,
│   │                         #   lock/, polkit/, background/, ...
│   └── settings/             # Pages of the settings app (BarConfig.qml, ...)
├── scripts/                  # Runtime helper scripts (colors, ai, ...) — not dev tools
└── design/                   # Vendored design documents — read before building any UI
```

Import scheme: `import qs.services`, `import qs.modules.common`, `import qs.modules.common.widgets`, etc. Services are `pragma Singleton` — reference them directly (`Audio.sink`, `Network.materialSymbol`).

## Widget Catalog

You can find widgets in [widget catalog](./widget-catalog.html).
Please keep it updated after making changes.

## Designs

`design/` holds vendored copies of the design documents this shell is built from,
so a design is readable from a clone with no login or MCP access. **If you are
implementing UI that has a design, read it first** — see `design/README.md` for how
to read a `.dc.html` and which state maps to which ticket.

⚠️ The hex values in `design/_ds/*/tokens.css` are a snapshot taken from one
wallpaper. Map each `var(--qs-*)` to its `Appearance` counterpart; copying a hex
literal into QML is a defect. See the theming rules below.

## Theming rules (non-negotiable)

Colors come from **matugen** (Material You from the wallpaper) → `~/.local/state/quickshell/user/generated/colors.json` → the `Appearance` singleton. The palette changes whenever the wallpaper does, so:

- **Never hardcode colors, sizes, fonts, or animation durations.** Use:
  - `Appearance.colors.*` (e.g. `colLayer0`, `colOnLayer1`, `colPrimaryContainer`) and `Appearance.m3colors.*`
  - `Appearance.font.pixelSize.*` / `Appearance.font.family.*`
  - `Appearance.rounding.*`, `Appearance.spacing.*`, `Appearance.sizes.*`
  - `Appearance.animation.*` (e.g. `Appearance.animation.elementMoveFast.colorAnimation.createObject(this)`)
- Prefer existing widgets from `modules/common/widgets/`: `StyledText`, `StyledRectangularShadow`, `RippleButton`, `MaterialSymbol` (Material Symbols icon font), `Revealer`, ...
- Write user-visible strings directly in English; this configuration intentionally has no i18n layer.

## Config options

`modules/common/Config.qml` is a Singleton wrapping a `FileView { watchChanges: true }` + `JsonAdapter`. Options are declared as nested `JsonObject`s:

```qml
property JsonObject bar: JsonObject {
    property bool bottom: false   // the declaration IS the default
    property JsonObject weather: JsonObject { property bool enable: false }
}
```

- User file: `~/.config/skill-shell/config.json`. It hot-applies on edit (50 ms debounce) **and is auto-rewritten by the shell** whenever any option changes from QML — don't be surprised when it reformats itself, and don't fight it for formatting.
- Read anywhere as `Config.options.bar.bottom` — fully reactive, no signal wiring needed.
- Settings app UI lives in `modules/settings/*Config.qml` (see `.agents/skills/add-config-option`).

## IPC & Hyprland keybinds

Each panel's Scope defines `IpcHandler { target: "..." }` functions and `GlobalShortcut { name: "..." }` entries (e.g. `modules/overview/Overview.qml` has target `search` with `toggle()`, `close()`, `clipboardToggle()`...).

- Hyprland keybinds (`~/.config/hypr/keybinds.conf`) invoke them: `qs -c skill ipc call search toggle`.
- List all live targets/functions: `qs -c skill ipc show`.
- Panel open/closed state lives in `GlobalStates.qml` properties (e.g. `GlobalStates.overviewOpen`).

## Verifying changes (do this after every edit)

Quickshell **hot-reloads on file save** — no restart needed.

1. **Did the reload succeed?** On failure, `ReloadPopup.qml` shows the QML error on screen. Headless check: `qs -c skill log -t 30` and look for QML errors mentioning your file. (Warnings about missing icons are normal noise.)
2. **Is the instance alive?** `qs list --all` — note: plain `qs list` errors with "Could not find default config"; always pass `--all` or `-c skill`.
3. **Exercise the feature headlessly:** find the target with `qs -c skill ipc show`, then e.g. `qs -c skill ipc call search toggle`, `qs -c skill ipc call osdVolume trigger`.
4. **Settings app** can be tested standalone without touching the shell: `qs -p ~/.config/quickshell/skill/settings.qml`.
   Open it straight on a tab with `QS_SETTINGS_PAGE=<name|index> qs -p ...` (name is case-insensitive, prefixes work),
   or switch tabs on a running window with `qs -p ~/.config/quickshell/skill/settings.qml ipc call settings openPage fans`
   (`listPages` / `currentPage` on the same target).
5. **Full restart — last resort only** (kills polkit agent + notifications briefly): `qs kill -c skill && qs -c skill -d`.

Details in `.agents/skills/verify-shell`.

## Common tasks

| Task                                    | How                                                                                                                                              |
| --------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------ |
| Add launcher action (`/foo`)            | **Zero code**: drop an executable script in `~/.config/skill-shell/actions/` — auto-appears under the `/` prefix, remaining query passed as args |
| Change a setting                        | Edit `~/.config/skill-shell/config.json` directly (hot-applies)                                                                                  |
| Add a bar widget                        | `.agents/skills/add-bar-widget`                                                                                                                  |
| Add a launcher search provider/prefix   | `.agents/skills/add-launcher-provider`                                                                                                           |
| Add a config option (+ settings UI)     | `.agents/skills/add-config-option`                                                                                                               |
| Verify a change works                   | `.agents/skills/verify-shell`                                                                                                                    |
| Sync the design system to Claude Design | `scripts/design/sync.sh`, then ask Claude Code to push `scripts/design/build/bundle`                                                             |

## Removing or refactoring a feature (hints)

Features are **not self-contained** — one threads through service singletons, panel modules, the panel-family loader, both bar variants, `Config.qml` schema, `Persistent.qml` state, `Directories.qml` paths, the settings app, and sometimes helper scripts. Before deleting, map the blast radius:

1. Grep broadly for service names, module dir, widget names, config keys (`options.X`, `policies.X`), and `GlobalStates.*` across **all** `*.qml`, not just the feature dir.
2. For each hit, decide **feature-specific (delete) vs shared (keep)**. Services, scripts, `policies.*` flags, and `GlobalStates` are often reused by unrelated features (other panels, the lock screen, wallpaper theming) — verify before assuming a dependency is dedicated.
3. Removing a panel = delete `modules/widgets/<panel>/` **and** drop its `import` + `PanelLoader { component: X {} }` line from `shell.qml` (the only importer of widgets panel modules).
4. Removing a bar entry point: fix **both** bar variants, and check for `id`-references to the removed widget from siblings and for `MouseArea` handlers that acted on it.
5. Deleting a `JsonObject` from `Config.qml`/`Persistent.qml` leaves orphan keys in the user's `config.json` until the next shell-side rewrite — harmless; don't hand-edit the JSON to chase them.
6. Also purge the settings UI (`modules/settings/*Config.qml`), or dead toggles linger.
7. **Transient hot-reload warnings are normal**: `TypeError: Cannot read property 'X' of undefined/null` during a reload or a `SwipeView`/tab-list rebuild is noise — confirm only that the property isn't one you changed.

## Gotchas

- **Launcher prefixes are defined in one table.** Prefix definitions, icons, shapes, and provider callbacks live in `modules/common/functions/SearchPrefixes.qml`. Adding a prefix requires adding a single record to the `prefixes` table — see the skill.
- **The bar is horizontal**: entry point in `modules/widgets/bar/BarContent.qml`.
- The bar adapts to screen width via `useShortenedForm` (0/1/2) and fixes middle-group widths via `centerSideModuleWidth` — gate wide widgets on `useShortenedForm`.
- `config.json` is rewritten by the shell ~50 ms after any QML-side option change; schema defaults live in `Config.qml`, the JSON only reflects current values.
- Single monitor setup; Hyprland master layout, gaps 5, rounding 8. Keyboard layouts `us,ir`.
- This directory is a git repository. Check the working tree before editing and preserve unrelated changes.

<!-- graft:start -->
## Graft — repo context graph

This repo is indexed in `graft/`: small linked markdown nodes that explain each
system and carry exact file:line spans, kept in sync with the code through git.

For ANY task here — understanding how something works, finding where code lives,
or scoping a change — get context from the graph before grepping or opening
source files. Re-ask freely (it's cheap) and reuse literal identifiers you
already have (symbol, error string, file name) as the query. New to this repo?
Run `graft map` first — a token-budgeted orientation (dir clusters, hubs,
hotspots), no LLM, no key.

- Run `graft ask "<your question>" --source` → ranked nodes with the relevant
  code spans inlined (each hit's ≤8-line crux by default; `--full` for whole
  definitions when the crux isn't enough). Match the tool to the task shape:
  for understanding or editing, the top node IS the answer — cite its
  `covers:` file:line spans and edit straight from `--source`. For
  exhaustive tasks ("every occurrence / every caller of this pattern"), ranked
  results are top-N, not complete — run `graft grep "<literal>"` instead
  (exhaustive over indexed files, grouped by enclosing symbol), falling back
  to raw `grep -rn` only for unindexed files.
- `graft skeleton <file>` → every definition's signature + span, ~10× cheaper
  than reading the file; use it to skim an API surface.
- `graft callers <symbol>` gives precomputed, exact edges — who calls this.
  Add `--direction out` for what it calls, or `--depth N` to walk
  transitively for the full blast radius. For structural questions, skip
  ranking and use this directly.
- Or browse: `graft/INDEX.md` lists every node; follow the links.
- Monorepos and folders of multiple repos rank fairly across sub-projects —
  hits carry `[scope/]` labels naming which one they're from. Narrow with
  `graft ask "<task>" --in <scope>/` once you know where you're working.

If a returned span is truncated ("+N more lines"), open the file at that exact
range before finalizing. Only open source files when a node genuinely lacks a
needed detail, and then at the exact file:line the node points to — never
re-read whole files.

After big code changes, refresh the graph with `graft build` (deterministic,
no API key, $0).
<!-- graft:end -->
