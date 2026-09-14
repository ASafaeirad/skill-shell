#!/usr/bin/env bash

set -uo pipefail

input="$(cat)"
state_root="${XDG_STATE_HOME:-${HOME}/.local/state}/quickshell/user"
cache_file="${state_root}/claude-usage.json"
now="$(date +%s)"

umask 077
mkdir -p -- "${state_root}"

snapshot="$(jq -ce --argjson captured_at "${now}" '
    select(.rate_limits.five_hour != null or .rate_limits.seven_day != null)
    | {
        capturedAt: $captured_at,
        sourceRevision: (
            (.session_id // "unknown") + ":"
            + ((.cost.total_api_duration_ms // 0) | tostring) + ":"
            + (.rate_limits | tostring)
        ),
        fiveHour: (.rate_limits.five_hour | if . == null then null else {
            usedPercent: .used_percentage,
            resetsAt: .resets_at,
            windowDurationMins: 300
        } end),
        sevenDay: (.rate_limits.seven_day | if . == null then null else {
            usedPercent: .used_percentage,
            resetsAt: .resets_at,
            windowDurationMins: 10080
        } end)
    }
' <<<"${input}" 2>/dev/null || true)"

if [[ -n "${snapshot}" ]]; then
    new_revision="$(jq -r '.sourceRevision' <<<"${snapshot}")"
    old_revision="$(jq -r '.sourceRevision // empty' "${cache_file}" 2>/dev/null || true)"
    if [[ "${new_revision}" != "${old_revision}" ]]; then
        temporary_file="$(mktemp "${state_root}/claude-usage.XXXXXX")"
        printf '%s\n' "${snapshot}" >"${temporary_file}"
        mv -f -- "${temporary_file}" "${cache_file}"
    fi
fi

# Preserve the user's existing Claude Code status line.
if command -v ccstatusline >/dev/null 2>&1; then
    printf '%s' "${input}" | ccstatusline
fi
