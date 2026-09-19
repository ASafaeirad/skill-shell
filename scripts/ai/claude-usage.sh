#!/usr/bin/env bash

set -uo pipefail

state_root="${XDG_STATE_HOME:-${HOME}/.local/state}/quickshell/user"
claude_config_root="${CLAUDE_CONFIG_DIR:-${XDG_CONFIG_HOME:-${HOME}/.config}/claude}"
credentials_file="${claude_config_root}/.credentials.json"
cache_file="${state_root}/claude-usage.json"
client_id="${CLAUDE_CODE_OAUTH_CLIENT_ID:-9d1c250a-e61b-44d9-88ed-5944d1962f5e}"
usage_url="https://api.anthropic.com/api/oauth/usage"
token_url="https://platform.claude.com/v1/oauth/token"
now="$(date +%s)"

umask 077
mkdir -p -- "${state_root}"

if [[ ! -r "${credentials_file}" ]]; then
    printf 'Claude credentials not found at %s\n' "${credentials_file}" >&2
    exit 1
fi

access_token="$(jq -er '.claudeAiOauth.accessToken | select(length > 0)' "${credentials_file}")" || exit 1
expires_at="$(jq -r '.claudeAiOauth.expiresAt // 0' "${credentials_file}")"

refresh_token() {
    local current_refresh_token scopes response new_access_token new_refresh_token expires_in refresh_expires_in
    current_refresh_token="$(jq -er '.claudeAiOauth.refreshToken | select(length > 0)' "${credentials_file}")" || return 1
    scopes="$(jq -r '.claudeAiOauth.scopes // [] | join(" ")' "${credentials_file}")"

    response="$(jq -cn \
            --arg refresh_token "${current_refresh_token}" \
            --arg client_id "${client_id}" \
            --arg scope "${scopes}" \
            '{grant_type: "refresh_token", refresh_token: $refresh_token, client_id: $client_id, scope: $scope}' \
        | curl --fail-with-body --silent --show-error --max-time 10 \
            --request POST \
            --header 'Content-Type: application/json' \
            --data-binary @- \
            "${token_url}")" || return 1

    new_access_token="$(jq -er '.access_token | select(length > 0)' <<<"${response}")" || return 1
    new_refresh_token="$(jq -r --arg fallback "${current_refresh_token}" '.refresh_token // $fallback' <<<"${response}")"
    expires_in="$(jq -er '.expires_in | numbers' <<<"${response}")" || return 1
    refresh_expires_in="$(jq -r '.refresh_token_expires_in // 0' <<<"${response}")"

    local latest_refresh_token temporary_file
    latest_refresh_token="$(jq -r '.claudeAiOauth.refreshToken // ""' "${credentials_file}")"
    if [[ "${latest_refresh_token}" != "${current_refresh_token}" ]]; then
        access_token="$(jq -er '.claudeAiOauth.accessToken | select(length > 0)' "${credentials_file}")" || return 1
        return 0
    fi

    temporary_file="$(mktemp "${claude_config_root}/.credentials.XXXXXX")"
    jq \
        --arg access_token "${new_access_token}" \
        --arg refresh_token "${new_refresh_token}" \
        --argjson expires_at "$(( $(date +%s%3N) + expires_in * 1000 ))" \
        --argjson refresh_expires_at "$(( refresh_expires_in > 0 ? $(date +%s%3N) + refresh_expires_in * 1000 : 0 ))" \
        --arg scope "$(jq -r '.scope // empty' <<<"${response}")" \
        '.claudeAiOauth.accessToken = $access_token
        | .claudeAiOauth.refreshToken = $refresh_token
        | .claudeAiOauth.expiresAt = $expires_at
        | if $refresh_expires_at == 0 then . else .claudeAiOauth.refreshTokenExpiresAt = $refresh_expires_at end
        | if $scope == "" then . else .claudeAiOauth.scopes = ($scope | split(" ")) end' \
        "${credentials_file}" >"${temporary_file}" || return 1
    chmod 600 "${temporary_file}"
    mv -f -- "${temporary_file}" "${credentials_file}"
    access_token="${new_access_token}"
}

if (( expires_at <= $(date +%s%3N) + 60000 )); then
    refresh_token || {
        printf 'Could not refresh Claude OAuth credentials\n' >&2
        exit 1
    }
fi

response="$(printf '%s\n' \
        "header = \"Authorization: Bearer ${access_token}\"" \
        'header = "anthropic-beta: oauth-2025-04-20"' \
        'header = "Content-Type: application/json"' \
    | curl --fail-with-body --silent --show-error --max-time 10 \
        --config - \
        "${usage_url}")" || exit 1

snapshot="$(jq -ce --argjson captured_at "${now}" '
    def reset_epoch:
        if . == null then null
        else sub("\\.[0-9]+"; "") | sub("\\+00:00$"; "Z") | fromdateiso8601
        end;
    {
        capturedAt: $captured_at,
        sourceRevision: tostring,
        fiveHour: (.five_hour | if . == null then null else {
            usedPercent: .utilization,
            resetsAt: (.resets_at | reset_epoch),
            windowDurationMins: 300
        } end),
        sevenDay: (.seven_day | if . == null then null else {
            usedPercent: .utilization,
            resetsAt: (.resets_at | reset_epoch),
            windowDurationMins: 10080
        } end)
    }
' <<<"${response}")" || exit 1

temporary_file="$(mktemp "${state_root}/claude-usage.XXXXXX")"
printf '%s\n' "${snapshot}" >"${temporary_file}"
mv -f -- "${temporary_file}" "${cache_file}"
