# Design system: Material 3 components

`modules/common/m3/` is the shell's component library. Each file is one component
from [Material 3](https://m3.material.io/components), named as Material 3 names it and
drawn only from `Appearance` tokens, so it follows the wallpaper palette.

```qml
import qs.modules.common            // Appearance
import qs.modules.common.widgets    // StyledText, MaterialSymbol and the shell widgets
import qs.modules.common.m3 as M3   // always with `as M3`

M3.Button { variant: "tonal"; text: "Retry"; materialIcon: "refresh"; onClicked: YtDlp.retry() }
```

**Always import it as `M3`.** Several names (`Button`, `Switch`, `Slider`, `TextField`,
`RadioButton`) also exist in `QtQuick.Controls`; the qualifier makes it unambiguous
which one a file means. The lint rejects an unqualified import.

To see every component live, with a property panel, run the explorer:

```sh
qs -p design-system.qml                                   # from the repo root
qs -p design-system.qml ipc call designSystem openTab Chip
```

## Rules

1. **Build from the catalog.** Before writing a `Rectangle` + `MouseArea`, a styled
   `RippleButton`, or an inline `component Foo: Rectangle`, find the Material 3
   component for it below. Pick the variant by emphasis, as the M3 guideline for that
   component describes.
2. **A missing component goes here, not inline in a panel.** Read its M3 guideline,
   add `modules/common/m3/<Name>.qml`, add a page to `design-system.qml`, and add a
   row to this table and to `widget-catalog.html`. See the `design-system` skill.
3. **Adjust through properties, not overrides.** If a panel needs a different look,
   add a property or variant to the component. Don't reassign `background`,
   `contentItem` or colours from a panel.
4. **Tokens only.** Colours, sizes, radii, spacing and animation come from
   `Appearance` (`colors`, `m3colors`, `sizes.m3*`, `rounding`, `spacing`,
   `stateLayer`, `animation`). Interactive colours come from
   `ColorUtils.stateLayer(container, content, Appearance.stateLayer.hover)`.

## Shared conventions

| Property | Meaning |
| --- | --- |
| `variant` | The M3 variant as a lowercase string: `"filled"`, `"tonal"`, `"outlined"`, … |
| `text` | The label (headline for `ListItem`) |
| `materialIcon` | A Material Symbols name (`"refresh"`). `icon` is taken by `AbstractButton` |
| `selected` | M3's selected state (toggle buttons, filter chips). **Controlled**: bind it to your state and change that state in `onClicked` |
| `toggleable` | The control is a toggle, so its unselected state wears the neutral surface roles rather than the variant's own |
| `enabled: false` | M3 disabled colours (38% content, 12% container). Don't fade with `opacity` |

## Catalog

Status: **native** is written in this directory against the M3 spec. **wraps** re-exports a
widget from `modules/common/widgets`. Use the M3 name in new code. The implementation can
then move into this directory later without changing any callers.

| M3 component | Use | Status | API |
| --- | --- | --- | --- |
| [Buttons](https://m3.material.io/components/buttons) | `M3.Button` | native | `variant`: filled · tonal · outlined · text · elevated; `shape`: round · square; `text`, `materialIcon`, `trailingText`, `toggleable`, `selected`, `selectedVariant`: filled · tonal, `content` (slot), `externalHover`, `error`; quick setting tile: `tileLayout`, `supportingText`, `leadingAction`, `leadingSelected` |
| [Button groups](https://m3.material.io/components/button-groups) | `M3.ButtonGroup` | native | `variant`: connected · segmented; connected children use `M3.Button` or `M3.IconButton`; segmented `options`, `currentValue`, `selected(value)`, optional `configKey`, `readOnly`, `equalWidth`, `surface`, `compact` |
| [Icon buttons](https://m3.material.io/components/icon-buttons) | `M3.IconButton` | native | `variant`: standard · filled · tonal · outlined; `size`: small · xsmall; `materialIcon`, `iconSource`, `tooltip`, `toggleable`, `selected`, `selectedVariant`: tonal, `iconRotation`, `error`, `dotColor` for a colour swatch |
| [FAB](https://m3.material.io/components/floating-action-button) | `M3.Fab` | wraps `FloatingActionButton` | `variant`: primary · secondary · tertiary; `size`: regular · toolbar; `iconText`, `buttonText`, `expanded` (extended FAB), `elevated`, `tooltip` |
| [Chips](https://m3.material.io/components/chips) | `M3.Chip` | native | `variant`: assist · filter · input · suggestion; `text`, `materialIcon`, `selected`, `readOnly` for a locked but legible choice, `compact` (28px), `removable`, `removeClicked()` |
| [Cards](https://m3.material.io/components/cards) | `M3.Card` | native | `variant`: filled · elevated · outlined; children stack in a column; `padding`, `spacing`, `interactive`, `clicked()`, controlled `selected`, `selectedVariant`: tonal · filled |
| [Dialogs](https://m3.material.io/components/dialogs) | `M3.Dialog`, `M3.DialogOverlay` + `M3.DialogCard` | wraps `WindowDialog`, `OverlayDialog` + `OverlayDialogCard` | Basic in-panel dialog: `show`, `dismiss()`, `backgroundWidth`, `backgroundHeight`; overlay: `open()`, `close()`, `dismissed()`, `closeFinished()`; card: `outlinedSurface`; content uses `M3.DialogTitle`, `M3.DialogParagraph` (`error`), `M3.DialogSectionHeader`, `M3.DialogButtonRow` |
| [Lists](https://m3.material.io/components/lists) | `M3.ListItem` | native | `text`, `overline`, `supportingText`, `leadingIcon` / `leadingIconSource` / `leadingText`, `trailingIcon`, `trailingText`, `selected`, `textFormat`, `monospace`, `interactive`, `compact`, `density` (0 to -3); children go to the trailing slot, `headlineLeadingData` before the headline, `supportingData` under it |
| [Menus](https://m3.material.io/components/menus) | `M3.Menu` | native | Filled menu surface for `M3.MenuItem` rows and `M3.Divider` groups |
| [Menus](https://m3.material.io/components/menus) | `M3.MenuItem` | native | `text`, `leadingIcon`, `leadingIconSource`, `trailingIcon`, `trailingText`, `selectionControl`: none · checkbox · radio + `checkState`, `density` (0 to -3), `reserveLeadingIcon`, `reserveSelectionControl` |
| [Menus](https://m3.material.io/components/menus) | `M3.ExposedDropdownMenu` | wraps `StyledComboBox` | `model`, `currentIndex`, `activated(index)`, `buttonIcon` |
| [Menus](https://m3.material.io/components/menus) | `M3.FilterableExposedDropdownMenu` | wraps `FilterableComboBox` | `sourceModel`, `selectedValue`, `valueActivated(value)`, `filterPlaceholderText`, `noResultsText`, `popupMaxHeight` |
| [Divider](https://m3.material.io/components/divider) | `M3.Divider` | native | `vertical`, `insetStart`, `insetEnd` |
| [Badges](https://m3.material.io/components/badges) | `M3.Badge` | native | `text` (empty draws the small dot; four characters at most) |
| [Checkbox](https://m3.material.io/components/checkbox) | `M3.Checkbox` | native | `text`, `checked`, `tristate`/`checkState`, `error` |
| [Radio button](https://m3.material.io/components/radio-button) | `M3.RadioButton` | wraps `StyledRadioButton` | `description`, `checked` |
| [Switch](https://m3.material.io/components/switch) | `M3.Switch` | wraps `StyledSwitch` | `checked`, `toggled()` |
| [Sliders](https://m3.material.io/components/sliders) | `M3.Slider` | wraps `StyledSlider` | `value`, `from`, `to`, `configuration: StyledSlider.Configuration.S` (the enum lives on `StyledSlider`) |
| [Text fields](https://m3.material.io/components/text-fields) | `M3.TextField` | wraps `MaterialTextField` | `text`, `placeholderText`, `readOnly` |
| [Text fields](https://m3.material.io/components/text-fields) | `M3.TextArea` | wraps `MaterialTextArea` | multiline `text`, `placeholderText`, `readOnly`, `wrapMode` |
| [Search](https://m3.material.io/components/search) | `M3.SearchBar` | native | the search bar's input: `text`, `placeholderText`, `compact` (40px); leading icon and trailing `M3.IconButton`s go beside it |
| [Progress indicators](https://m3.material.io/components/progress-indicators) | `M3.LinearProgressIndicator` | wraps `StyledProgressBar` | `value`, `wavy`, `indeterminate` |
| [Progress indicators](https://m3.material.io/components/progress-indicators) | `M3.CircularProgressIndicator` | wraps `CircularProgress` | `value`, `indeterminate`, `fill`, `implicitSize` |
| [Loading indicator](https://m3.material.io/components/loading-indicator) | `M3.LoadingIndicator` | wraps `MaterialLoadingIndicator` | `loading` |
| [Tooltips](https://m3.material.io/components/tooltips) | `M3.Tooltip` | wraps `StyledToolTip` | `text`, `extraVisibleCondition`; `M3.IconButton` has a `tooltip` property already |
| [Snackbar](https://m3.material.io/components/snackbar) | `M3.Snackbar` | native | `variant`: single-line · two-line; `text`, `supportingText`, `leadingIcon`, `actionText`, `actionTooltip`, `progress`, `actionClicked()` |
| [Navigation rail](https://m3.material.io/components/navigation-rail) | `M3.NavigationRail` | wraps `NavigationRailTabs` | `model: [{ name, icon }]`, `currentIndex`, `expanded`, `tabSelected(index)` |
| [Tabs](https://m3.material.io/components/tabs) | `M3.Tabs` + `M3.Tab` | native | `variant`: secondary · compact (toolbar pill); `currentIndex`, `incrementCurrentIndex()`, `decrementCurrentIndex()`; tab `text`, `materialIcon`, `variant` |
| [Toolbars](https://m3.material.io/components/toolbars) | `M3.Toolbar` + `M3.ToolbarTextField` | native | `variant`: floating · docked; `elevated`, `padding`, `spacing`; children form the row: `M3.IconButton` (toggles with `selectedVariant: "tonal"`), `M3.ToolbarTextField` (`placeholderText`, `drawsOwnText`); pair a `M3.Fab { size: "toolbar"; variant: "tertiary" }` beside it |

### M3 components not in the catalog yet

These are served by a widget in `modules/common/widgets` until they are added here. Use the
existing widget rather than writing a new one, and consider adding the M3 component instead.

| M3 component | Existing widget |
| --- | --- |
| [Search](https://m3.material.io/components/search) view (the expanded results surface; `M3.SearchBar` is in the catalog) | the launcher's `SearchWidget` |
| [Date pickers](https://m3.material.io/components/date-pickers) | the sidebar's `CalendarWidget` grid, built from `M3.Button` toggles |
| [Sheets](https://m3.material.io/components/bottom-sheets), [Time pickers](https://m3.material.io/components/time-pickers), [Carousel](https://m3.material.io/components/carousel) | none yet |

### Shell foundations (not M3 components, keep using them)

`StyledText` (all text), `MaterialSymbol` (all icons), `StyledRectangularShadow` (elevation),
`StyledFlickable` / `StyledListView` / `StyledScrollBar` (scrolling), `Revealer`,
`FadeLoader`, `StatusBadge` (a labelled status pill — not an M3 badge), `NoticeBox`,
`ContentPage` / `ContentSection` / `ConfigRow` / `ConfigSwitch` / `ConfigSpinBox` (settings pages).

## Migrating a widget

Migrate one panel at a time and leave its behaviour alone.

1. Run `.agents/skills/design-system/lint.py --all <panel files>`. It lists legacy widgets with
   their M3 replacements, inline components that reinvent one, and hard-coded colours.
2. Replace them one at a time. `StyledSwitch` → `M3.Switch` and the other wrapped
   components are drop-in. `DialogButton` → `M3.Button { variant: "text" }` and
   `RippleButtonWithIcon` → `M3.Button { materialIcon: ... }` need their properties renamed:
   `buttonText` → `text` on `DialogButton`, and `mainText` → `text`, `primary: true` →
   `variant: "filled"` (otherwise `"tonal"`) on `RippleButtonWithIcon`. `materialIcon` keeps its name.
3. Styled `RippleButton`s and inline components need a closer look. Name the M3 component the
   design means, then pick the variant. If none fits, add a variant or property here (Rule 3).
4. Preview it (`.agents/skills/preview-widget`) and compare it with the design in `design/`
   if the panel has one.

### Backlog at the time of writing

| Pattern | Count | Replacement |
| --- | --- | --- |
| `StyledToolTip` | 43 | `M3.Tooltip`, or `M3.IconButton { tooltip }` |
| `RippleButtonWithIcon` | 12 | `M3.Button { materialIcon }` |
| Inline `component X: Rectangle/RippleButton` | 8 | `Separator` → `M3.Divider`; `TitlebarButton`, `WidgetButton` → `M3.IconButton`; `BigRecorderButton` → `M3.Button` |
| `MaterialTextField` | 6 | `M3.TextField` |
| `DialogButton` | 2 | `M3.Button { variant: "text" }` |
| Hex colour literals | 4 | `regionSelector`, `screenTranslator` overlays: an `Appearance` token (`colScrim`, …) |
| 1 px `Rectangle` dividers | 4 | `M3.Divider` |
| `StyledProgressBar` | 3 | `M3.LinearProgressIndicator` |
| Other wrapped widgets (`StyledSwitch`, `MaterialLoadingIndicator`) | 3 | the `M3.*` name for each |

`bar` and `sidebarRight` are done. The largest area left is `settings` (39 findings),
then `overlay` and `gmailInbox` (10 each).
