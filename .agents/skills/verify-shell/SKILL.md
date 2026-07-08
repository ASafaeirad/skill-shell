---
name: verify-shell
description: Verify a Quickshell change is working - check hot-reload succeeded, read logs, exercise features via IPC. Use after any edit to files, or when the shell misbehaves or a panel stops appearing.
---

# Verify a Quickshell change

Quickshell hot-reloads the whole config on file save. Never restart the shell just to "apply" a change.

## Check loop

1. **Reload status.** A failed reload shows an on-screen popup with the QML error (`ReloadPopup.qml`). Headless equivalent:
   ```sh
   qs -c ii log -t 30
   ```
   Look for QML errors referencing the file you edited (`... .qml:LINE: error`). Append `-f` to follow live while re-saving the file.

   **Benign noise to ignore:** icon lookup warnings, `Could not find icon`, Wayland protocol chatter, font warnings.

2. **Instance alive?**
   ```sh
   qs list --all
   ```
   Must show the instance with config path `.../quickshell/ii/shell.qml`.
   ⚠️ Plain `qs list` always errors with "Could not find default config" — that is not a failure signal; use `--all` or `-c ii`.

3. **Exercise the feature headlessly.** Find the IPC surface, then drive it:
   ```sh
   qs -c ii ipc show                     # lists all targets + functions
   qs -c ii ipc call search toggle       # example: open the launcher
   qs -c ii ipc call search close
   ```
   Panel visibility state lives in `GlobalStates.qml` properties if you need to reason about it.

4. **Settings app** changes can be tested without touching the running shell:
   ```sh
   qs -p ~/.config/quickshell/ii/settings.qml
   ```

## Escalation ladder (in order)

1. Re-save the file (touch it) to force another reload; re-check logs.
2. If the error is in your edit: fix it. The shell keeps running the last good state while reload fails, so there's no rush.
3. Only if the shell state is genuinely corrupted (panels gone, IPC dead):
   ```sh
   qs kill -c ii && qs -c ii -d
   ```
   ⚠️ This briefly kills the **polkit agent and notification daemon** (the shell provides both). Never leave the shell dead; confirm it's back with `qs list --all`.
