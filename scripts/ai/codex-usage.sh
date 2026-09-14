#!/usr/bin/env bash

set -uo pipefail

state_root="${XDG_STATE_HOME:-${HOME}/.local/state}/quickshell/user"
cache_file="${state_root}/codex-usage.json"
now="$(date +%s)"

umask 077
mkdir -p -- "${state_root}"

coproc CODEX_USAGE_SERVER { timeout 10 codex app-server --stdio 2>/dev/null; }

if [[ -z "${CODEX_USAGE_SERVER_PID:-}" ]]; then
    exit 1
fi

printf '%s\n' \
    '{"method":"initialize","id":0,"params":{"clientInfo":{"name":"quickshell_ai_usage","title":"Quickshell AI usage","version":"0.1.0"}}}' \
    '{"method":"initialized","params":{}}' \
    '{"method":"account/rateLimits/read","id":1,"params":{"excludeResetCreditDetails":true}}' \
    >&"${CODEX_USAGE_SERVER[1]}"

response=""
while IFS= read -r -t 10 line <&"${CODEX_USAGE_SERVER[0]}"; do
    if jq -e '.id == 1' >/dev/null 2>&1 <<<"${line}"; then
        response="${line}"
        break
    fi
done

kill "${CODEX_USAGE_SERVER_PID}" 2>/dev/null || true
wait "${CODEX_USAGE_SERVER_PID}" 2>/dev/null || true

if [[ -z "${response}" ]]; then
    exit 1
fi

snapshot="$(jq -ce --argjson captured_at "${now}" '
    if .error then error(.error.message // "Codex usage request failed") else
        (.result.rateLimitsByLimitId.codex // .result.rateLimits) as $limit
        | {
            capturedAt: $captured_at,
            planType: $limit.planType,
            ordinaryUsageAllowed: .result.ordinaryUsageAllowed,
            fiveHour: ($limit.primary | if . == null then null else {
                usedPercent: .usedPercent,
                windowDurationMins: .windowDurationMins,
                resetsAt: .resetsAt
            } end),
            sevenDay: ($limit.secondary | if . == null then null else {
                usedPercent: .usedPercent,
                windowDurationMins: .windowDurationMins,
                resetsAt: .resetsAt
            } end)
        }
    end
' <<<"${response}")" || exit 1

temporary_file="$(mktemp "${state_root}/codex-usage.XXXXXX")"
printf '%s\n' "${snapshot}" >"${temporary_file}"
mv -f -- "${temporary_file}" "${cache_file}"
