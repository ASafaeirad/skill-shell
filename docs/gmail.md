# Gmail inbox

The Gmail widget shows one wallpaper-themed account dot and unread count per
enabled account in the bar. Left-click opens the inbox. Use its account dots to
filter messages, or open a message in Gmail from its row. Right-click the chip
to refresh immediately. This
version requests `https://www.googleapis.com/auth/gmail.readonly` and cannot
change messages.

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
address, palette key, enabled state, widget state, and refresh interval.

The shell invokes `scripts/gmail/gmail_helper.py` with only `login` or `sync`
on the command line. It sends credentials as JSON over stdin. The helper uses
the system Python standard library, owns every Google and Gmail endpoint, and
returns normalized JSON. Exit code 2 means authorization expired, and exit code
3 means the network is unreachable.
