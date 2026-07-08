---
name: add-bar-widget
description: Add or modify a widget in the illogical-impulse bar (indicators, clock area, resource monitors). Use when asked to add something to the bar / top panel / status bar.
---

# Add a bar widget

## 1. Write the widget

Create `modules/ii/bar/MyWidget.qml`. Model it on `ClockWidget.qml` (49 lines — the minimal shape):

```qml
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    implicitWidth: rowLayout.implicitWidth
    implicitHeight: Appearance.sizes.barHeight

    RowLayout {
        id: rowLayout
        anchors.centerIn: parent
        spacing: 4
        StyledText {
            font.pixelSize: Appearance.font.pixelSize.large
            color: Appearance.colors.colOnLayer1
            text: SomeService.value   // data from a services/ singleton
        }
    }
}
```

Rules: theme tokens only (`Appearance.colors/font/sizes/rounding/animation.*`), `StyledText`/`MaterialSymbol` from common widgets, `Translation.tr()` for visible strings. Data belongs in a `services/` singleton (check the ~45 existing ones — Battery, Network, ResourceUsage, DateTime... — before writing a new one). Hover popups: `MouseArea { id: mouseArea; ... MyPopup { hoverTarget: mouseArea } }` like ClockWidget.

## 2. Wire it into the bar

Edit `modules/ii/bar/BarContent.qml`. Placement options:

| Region             | Where in BarContent.qml                                                                     |
| ------------------ | ------------------------------------------------------------------------------------------- |
| Left side          | `leftSectionRowLayout` (inside `barLeftSideMouseArea`; left side scroll = brightness)       |
| Middle-left group  | `BarGroup { id: leftCenterGroup }` (Resources + Media)                                      |
| Middle-right group | `BarGroup { id: rightCenterGroupContent }` (Clock, UtilButtons, Battery)                    |
| Right side         | `rightSectionRowLayout` (`layoutDirection: Qt.RightToLeft` — first child renders rightmost) |

Gotchas:
- Middle `BarGroup`s have **fixed width** (`root.centerSideModuleWidth`) — a wide widget will squeeze its siblings.
- The bar shortens on narrow screens: gate non-essential widgets with `visible: root.useShortenedForm === 0` (or `< 2`), matching how `ActiveWindow`/`SysTray` do it.

## 3. Decide variant coverage (consciously, don't skip)

- **Vertical bar** is a separate composition: `modules/ii/verticalBar/VerticalBarContent.qml` with its own widget variants (`VerticalClockWidget.qml`...). If the user uses `Config.options.bar.vertical`, add a variant or state that you didn't.
- **Waffle family** has its own bar (`modules/waffle/`) — usually out of scope; say so.

## 4. Optional: visibility toggle

Add `property bool enable` under `Config.qml`'s `bar` JsonObject and gate the widget with `visible:`/`Loader { active: ... }` (see the weather Loader at the bottom of BarContent.qml for the pattern). Full recipe: `add-config-option` skill.

## 5. Verify

Save → hot reload. Follow the `verify-shell` skill: `qs -c ii log -t 30` for QML errors, then eyeball the bar (or ask the user to).
