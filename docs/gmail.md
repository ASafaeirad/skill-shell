# Gmail inbox

The Gmail widget shows one wallpaper-themed account dot and unread count per
enabled account in the bar. Left-click opens the inbox. Use its account dots to
filter messages, or open a message in Gmail from its row. Hover over a message
to archive it, mark it read or unread, add a label, move it to trash, or open it
in Gmail. Right-click the chip to refresh immediately. These actions use
`https://www.googleapis.com/auth/gmail.modify`. Accounts signed in with the
earlier read-only permission must sign in again before mail actions work.

The shell keeps the last successful inbox in its cache. If Gmail is unreachable,
the popover continues to show that inbox, labels it with the cache time, and
shows the next automatic retry plus a **Retry now** action. Repeated failures
double the polling delay up to 30 minutes. Any successful account sync restores
the configured interval.

If one account's refresh token expires, only that account shows a **Reconnect**
action. Other accounts continue to sync and display their cached messages.

New-mail desktop notifications are off by default. Enable them under
**Settings > Gmail**, then use the notification icon on an account row to mute
or unmute that inbox. The first successful poll after startup is silent. Later
polls notify only for unread message IDs absent from the previous successful
sync, and more than three new messages produce one summary notification.

## Google setup

1. Create or select a project in Google Cloud Console.
2. Enable the Gmail API.
3. Configure the OAuth consent screen.
4. Create an OAuth client with the application type **Desktop app**.
5. Open **Settings > Gmail**, enter the client ID and secret, and select
   **Sign in with Google**.

Google expires refresh tokens after seven days while an OAuth consent screen
remains in **Testing**. Set the app to **In production**, then accept the
unverified-app warning during sign-in, to keep the refresh token. A personal
OAuth client does not need Google verification when only its owner uses it.

## Storage and process boundary

The system keyring stores the OAuth client ID, client secret, and account
refresh tokens. The shell config stores only the account ID, label, email
address, palette key, enabled state, notification preference, widget state, and
refresh interval. The last successful inbox is stored in
`~/.cache/quickshell/gmail/inbox.json` so it survives a shell restart.

The shell invokes `scripts/gmail/gmail_helper.py` with `login`, `sync`, or `action`
on the command line. It sends credentials as JSON over stdin. The helper uses
the system Python standard library, owns every Google and Gmail endpoint, and
returns normalized JSON. Exit code 2 means authorization expired, and exit code
3 means the network is unreachable.
