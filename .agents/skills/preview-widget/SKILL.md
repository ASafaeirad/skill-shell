---
name: preview-widget
description: Render a panel/widget from THIS checkout (e.g. a git worktree) in a throwaway Quickshell instance next to the live shell, and screenshot it for visual debugging. Use when you need to see UI you changed, when the live `qs -c skill` runs a different branch, or when asked to screenshot a widget.
---

# Preview and screenshot a widget from a worktree

The live shell (`qs -c skill`) runs from `~/.config/quickshell/skill` (the `main`
checkout), so edits in a worktree never reach it. Don't point the live shell at your
worktree and don't restart it (it owns the polkit agent and notifications). Instead, start
a **second, throwaway instance** that loads just one panel from your checkout.

`preview.sh` (next to this file) does it all. Run it from your checkout; it uses the
checkout it lives in:

```sh
P=.agents/skills/preview-widget/preview.sh

H=$($P start SidebarRight)       # loads modules/widgets/*/SidebarRight.qml, calls open()
$P shot "$H"                     # → /tmp/skill-preview-XXXX/shot-HHMMSS.png
# Read the PNG to look at it. Edit QML → it hot-reloads into the harness → shoot again.
$P stop "$H"                     # always clean up
```

| Command | What it does |
| --- | --- |
| `start <Type> [--no-open]` | Harness for `modules/widgets/*/<Type>.qml`. Calls `open()` unless `--no-open` (use that for always-visible panels like `Bar`, or ones without `open()`). Prints the harness dir `$H`. Load errors are printed and the harness is removed. |
| `start --qml FILE` | Use your own `shell.qml` (for a sub-widget, fake data, a specific state). Import from `qs.*` as usual. |
| `shot $H [namespace] [out.png]` | `grim` the harness's largest layer surface (filter by `WlrLayershell.namespace`, e.g. `quickshell:bar`), falling back to its `FloatingWindow`. Pass `""` as the namespace if you only want to set `out.png`. `--screen` captures the whole monitor. |
| `ipc $H <target> <fn> [args]` | Drive the harness, e.g. `ipc $H sidebarRight close`. Targets: `qs -p $H ipc show`. |
| `log $H [-f] [-t N]` | Harness logs (QML errors after a hot reload show up here). |
| `list` / `stop $H` / `stop all` | `stop all` only kills harnesses built from your checkout. |

## Things to know

- **Shared state.** The harness uses the same `~/.config/skill-shell/config.json` and
  persisted state files as the live shell. Changing a `Config.options.*` value in the
  harness changes the user's real config. Some panels also have side effects when opened
  (`SidebarRight` marks all notifications read). Avoid panels that write things you
  don't want written.
- **Same screen.** The harness draws on the real monitor, over the live shell. `shot`
  matches on the harness PID, so the live shell's copy of the same panel isn't captured.
  Panels with an exclusive zone (the `Bar`) push windows aside until you `stop`.
- **Shortcuts.** For `Panel` subclasses the generated harness sets
  `hasToggleShortcut: false; hasOpenCloseShortcuts: false` so it doesn't grab the live
  shell's Hyprland global shortcuts. Do the same in a custom `--qml`.
- **`shapes/` in worktrees.** `modules/common/widgets/shapes` is a gitlink with no
  `.gitmodules`, so worktrees get an empty dir, and anything that uses
  `MaterialShape` then fails with `module "qs.modules.common.widgets.shapes" is not
  installed`. `start` copies it from the main checkout automatically (git ignores the
  contents).
- **Other agents** may have their own harnesses running (`qs list --all`). Only stop your
  own. Never use `qs kill -c skill`.
- If `shot` finds no surface, the panel isn't open or mapped yet. Try
  `ipc $H <target> open`, wait a moment, or run
  `hyprctl layers -j | jq '.[].levels[][] | select(.pid==PID)'`.

## Custom harness example

For a state `open()` can't reach, write the harness yourself:

```qml
//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic
import QtQuick
import Quickshell
import qs.modules.common
import qs.modules.widgets.gmailInbox

ShellRoot {
    LazyLoader {
        active: Config.ready
        component: GmailInbox {
            hasToggleShortcut: false
            Component.onCompleted: open()
        }
    }
}
```

```sh
H=$($P start --qml /tmp/my-harness.qml) && $P shot "$H"
```
