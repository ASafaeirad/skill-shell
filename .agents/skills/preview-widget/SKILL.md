---
name: preview-widget
description: Run one skill-shell widget from a worktree in its own Quickshell instance for visual review, without restarting the main shell. Use when a worktree UI change needs to be opened on the desktop.
---

# Preview a widget from a worktree

The desktop's `qs -c skill` instance loads the main checkout. Opening its IPC target does not show worktree edits. The full `shell.qml` also owns the polkit agent and notification daemon, so use a small preview entry point instead of launching the whole worktree shell.

1. Create a temporary directory outside the repo. Symlink the worktree's `modules/`, `services/`, `scripts/`, `assets/`, and `GlobalStates.qml` into it. Add other root files only if the widget needs them. Symlinks keep the preview on the current worktree code and allow hot reload when a linked QML file changes.
2. Write `shell.qml` in that directory with a `ShellRoot` containing only the widget. Import the widget's module. For example, the Gmail inbox preview uses:

   ```qml
   import QtQuick
   import Quickshell
   import qs.modules.widgets.gmailInbox

   ShellRoot {
       GmailInbox {
           id: inbox
           Component.onCompleted: inbox.open()
       }
   }
   ```

3. Launch with `qs -p "$preview/shell.qml" -d`. Use that exact `-p` path for `log` and `ipc` calls too, such as `qs -p "$preview/shell.qml" ipc call gmailInbox open`. Check `qs list --all` to confirm both the main shell and the preview are alive, then check `qs -p "$preview/shell.qml" log -t 30` for QML errors.
4. Leave the preview open while the user is reviewing it. When finished, stop only that instance with `qs kill -p "$preview/shell.qml"`, then remove the temporary directory. Never use `qs kill -c skill` for preview cleanup.

The preview still uses real services and the user's configuration. Opening a widget can therefore trigger its normal service work; choose the smallest widget and service set needed for the review. Follow `verify-shell` for reload and IPC checks after edits.
