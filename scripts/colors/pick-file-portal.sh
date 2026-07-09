#!/usr/bin/env bash
# Open a file picker through xdg-desktop-portal's FileChooser so the wallpaper
# picker looks identical to every other portal-aware app on the system.
# Falls back to kdialog, then zenity, when no portal is reachable.
#
# Usage:  pick-file-portal.sh [title] [start_dir]
# Prints the chosen absolute path on stdout (empty if cancelled).

set -euo pipefail

TITLE="${1:-Choose wallpaper}"
START_DIR="${2:-$PWD}"

PORTAL_DEST="org.freedesktop.portal.Desktop"
PORTAL_PATH="/org/freedesktop/portal/desktop"

# Image + video globs, kept in sync with services/Wallpapers.qml `extensions`.
FILTERS="[('Images & videos', [\
(uint32 0, '*.jpg'), (uint32 0, '*.jpeg'), (uint32 0, '*.png'), \
(uint32 0, '*.webp'), (uint32 0, '*.avif'), (uint32 0, '*.bmp'), \
(uint32 0, '*.svg'), (uint32 0, '*.mp4'), (uint32 0, '*.webm'), \
(uint32 0, '*.mkv'), (uint32 0, '*.avi'), (uint32 0, '*.mov')])]"

uri_to_path() {
    # Strip file:// and percent-decode.
    python3 - "$1" <<'PY'
import sys, urllib.parse
u = sys.argv[1]
if u.startswith("file://"):
    u = u[7:]
sys.stdout.write(urllib.parse.unquote(u))
PY
}

portal_available() {
    command -v gdbus >/dev/null 2>&1 || return 1
    gdbus call --session --dest "$PORTAL_DEST" --object-path "$PORTAL_PATH" \
        --method org.freedesktop.DBus.Properties.Get \
        org.freedesktop.portal.FileChooser version >/dev/null 2>&1
}

pick_via_portal() {
    local token handle tmp mon_pid line uri i

    token="wallpaper_$$_$RANDOM"

    # OpenFile returns the Request handle immediately; the chosen file arrives
    # later on that object's Response signal. The portal keeps the dialog alive
    # after this call returns, and since a human drives the picker the gap before
    # we subscribe below is far too small for the Response to slip past.
    handle=$(gdbus call --session --dest "$PORTAL_DEST" --object-path "$PORTAL_PATH" \
        --method org.freedesktop.portal.FileChooser.OpenFile \
        "" "$TITLE" \
        "{'handle_token': <'$token'>, 'accept_label': <'Select'>, \
          'modal': <false>, 'multiple': <false>, \
          'current_folder': <b'$START_DIR'>, 'filters': <$FILTERS>}" \
        2>/dev/null) || return 1

    # handle looks like: (objectpath '/org/.../request/1_23/wallpaper_...',)
    handle=${handle#*\'}
    handle=${handle%\'*}
    [[ "$handle" == /org/* ]] || return 1

    # Watch the request object for its Response signal (broadcast on the bus).
    tmp=$(mktemp)
    gdbus monitor --session --dest "$PORTAL_DEST" --object-path "$handle" >"$tmp" 2>/dev/null &
    mon_pid=$!

    uri=""
    for ((i = 0; i < 1800; i++)); do   # give up after ~30 min of no answer
        kill -0 "$mon_pid" 2>/dev/null || break
        if grep -q "::Response" "$tmp"; then
            line=$(grep "::Response" "$tmp" | head -n1)
            # Response is (uint32 code, {'uris': <['file:///...']>}); cancel => none.
            uri=$(printf '%s\n' "$line" | grep -oE "file://[^']+" | head -n1 || true)
            break
        fi
        sleep 1
    done

    kill "$mon_pid" 2>/dev/null || true
    rm -f "$tmp"
    [[ -n "$uri" ]] && uri_to_path "$uri"
    return 0
}

pick_via_fallback() {
    if command -v kdialog >/dev/null 2>&1; then
        kdialog --getopenfilename "$START_DIR" --title "$TITLE" 2>/dev/null || true
    elif command -v zenity >/dev/null 2>&1; then
        zenity --file-selection --filename="$START_DIR/" --title="$TITLE" 2>/dev/null || true
    fi
}

if portal_available; then
    pick_via_portal
else
    pick_via_fallback
fi
