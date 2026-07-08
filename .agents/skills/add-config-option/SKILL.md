---
name: add-config-option
description: Add a new user-configurable option to the shell (Config.options.*), optionally with a settings-app control. Use when adding any toggle, threshold, string, or list setting to illogical-impulse.
---

# Add a config option

## 1. Declare the schema (this IS the default)

`modules/common/Config.qml` — find the right nested `JsonObject` (e.g. `bar`, `search`, `sidebar`) or create one:

```qml
property JsonObject myFeature: JsonObject {
    property bool enable: true          // defaults live here, in QML
    property int intervalSeconds: 10
    property list<string> excluded: []
}
```

`~/.config/illogical-impulse/config.json` only stores current values — users who never touched the option get the QML default. Supported types: `bool`, `int`, `real`, `string`, `list<string>`, nested `JsonObject`.

## 2. Consume it

`Config.options.myFeature.enable` anywhere — fully reactive, no signal wiring. Writes from QML (`Config.options.x = y`) persist automatically: the shell **rewrites config.json ~50 ms after any change**. Config edits by the user hot-apply the same way (FileView watches the file).

## 3. Optional: settings-app control

Add to the matching page in `modules/settings/` (`BarConfig.qml`, `GeneralConfig.qml`, `ServicesConfig.qml`...). Verified pattern:

```qml
ContentSection {
    icon: "tune"                        // Material Symbols name
    title: Translation.tr("My feature")
    ConfigSwitch {
        buttonIcon: "toggle_on"
        text: Translation.tr("Enable my feature")
        checked: Config.options.myFeature.enable
        onCheckedChanged: Config.options.myFeature.enable = checked;
    }
}
```

Other controls in `modules/common/widgets/`: `ConfigSpinBox`, `ConfigSlider`, `ConfigSelectionArray` (multi-choice; see "Bar position" in BarConfig.qml), `ConfigRow`/`ContentSubsection` for layout. All labels via `Translation.tr()`.

## 4. Verify

- Flip the value in `~/.config/illogical-impulse/config.json` and watch the UI react (no restart).
- Settings page runs standalone: `qs -p ~/.config/quickshell/ii/settings.qml` — toggle the control, confirm config.json updates.
- Check `qs -c ii log -t 30` for QML errors after the Config.qml edit (`verify-shell` skill).

Gotcha: don't hand-edit config.json while also changing values from QML in the same moment — the shell's debounced rewrite can clobber the file edit.
