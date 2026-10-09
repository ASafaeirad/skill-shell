---
name: design-system
description: Build UI from the shell's Material 3 component library (qs.modules.common.m3), add a missing M3 component to it, or migrate an existing widget onto it. Use whenever you write or change any visible QML — buttons, chips, cards, lists, toggles, fields, progress, dividers — or when asked to add a component to the design system or migrate a widget.
---

# Design system (Material 3)

The component library is `modules/common/m3/`, imported as `import qs.modules.common.m3 as M3`.
Its catalog, conventions and migration backlog are in **`modules/common/m3/README.md`**. Read
that first. It is short and it is the source of truth.

## Building UI

1. **Name the M3 component** for each control in the design or task (button, icon button,
   chip, card, list item, divider, …). Check the [M3 guideline](https://m3.material.io/components)
   when you are not sure which one or which variant fits.
2. **Use it from the catalog**: `M3.Button { variant: "tonal" }`, not a `RippleButton`
   restyled in the panel, and not an inline `component PillButton: RippleButton`.
3. **Missing?** Check the README's "not in the catalog yet" table for an existing widget. If
   there is none, or the component is worth adding, add it (below) before using it. Never
   write a one-off in the panel.
4. **Different look needed?** Add a property or variant to the component, not an override in
   the panel.
5. Before finishing, run the lint:

   ```sh
   .agents/skills/design-system/lint.py                # whole repository
   .agents/skills/design-system/lint.py FILE            # whole selected file
   .agents/skills/design-system/lint.py --changed       # added lines on this branch
   .agents/skills/design-system/lint.py --all FILE      # explicit whole-file scan
   ```

   The default scan includes tracked and non-ignored untracked QML, even when git is
   clean. Legacy widgets with M3 replacements are errors outside the shared widget
   and M3 library directories. Hex colours outside `modules/common/Appearance.qml`
   and M3 imports without `as M3` are also errors. Errors exit with status 1.
   Inline components and possible 1px dividers remain advisory warnings.
   `--changed --base REF` selects added lines relative to REF's merge base.
   Fix every error. For each warning, either act on it or say why it doesn't apply.

## Adding a component

1. Read the M3 page for it: anatomy, variants, states, and the colour roles of each part.
2. Create `modules/common/m3/<M3Name>.qml`:
   - Use the name Material 3 uses (`Chip`, `ListItem`, `Checkbox`). Don't prefix it.
   - Start with a doc comment: what it is, the M3 URL, one usage line, and the variants.
   - Follow the shared conventions: `variant` string, `text`, `materialIcon`, controlled
     `selected`, and disabled colours through `enabled`.
   - Use only tokens. Add missing geometry to `Appearance.sizes` as `m3<Thing>` and state
     opacities to `Appearance.stateLayer`, and compute interactive colours with
     `ColorUtils.stateLayer(container, content, opacity)`.
   - Build on `RippleButton` for anything clickable, and use `StyledText` and `MaterialSymbol`
     for text and icons.
   - ⚠️ Inside this directory, `Button`, `Switch`, `Slider`, `TextField` and `RadioButton` mean
     the M3 files, not `QtQuick.Controls`. To extend a Controls type with one of those names,
     go through its `modules/common/widgets` wrapper.
   - If a widget in `modules/common/widgets` already implements it, add a one-line
     wrapper (see `Tooltip.qml`) instead of copying it.
3. Add a page to `design-system.qml`: add the name to `m3Tabs`, give it an icon in
   `tabIcons`, add its variants to `variantOptions`, map it in `componentForTab`, and write
   a `Component` with a live example driven by the property panel and one showing all
   variants and states.
4. Add a row to the catalog in `modules/common/m3/README.md`, and remove the row from
   "not in the catalog yet" if there was one. Add an entry to `widget-catalog.html`.
5. Verify (next section).

## Migrating a widget

Follow "Migrating a widget" in the README. Migrate one panel per change, and keep behaviour and
layout the same unless the task says otherwise. Start with the lint's `--all` output for
that panel's files.

## Verifying

The design-system explorer runs standalone and hot-reloads, so it doesn't touch the live
shell:

```sh
qs -p "$PWD/design-system.qml" -d
qs -p "$PWD/design-system.qml" ipc call designSystem openTab <Name>
qs -p "$PWD/design-system.qml" log -t 50 | grep -E "ERROR|WARN"
grim -g "$(hyprctl clients -j | jq -r '.[] | select(.title=="Skill Shell design system") | "\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')" /tmp/ds.png
qs kill -p "$PWD/design-system.qml"
```

In a fresh worktree, `modules/common/widgets/shapes` (a gitlink) may be empty. In that case
`LoadingIndicator` fails to load. Copy the directory from the main checkout for the preview,
and don't commit it.

For a panel that uses the components, see `.agents/skills/preview-widget`.
