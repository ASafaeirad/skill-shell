#!/usr/bin/env bash

CONFIG_FILE="$HOME/.config/skill-shell/config.json"
JSON_PATH=".screenRecord.savePath"

CUSTOM_PATH=$(jq -r "$JSON_PATH // empty" "$CONFIG_FILE" 2>/dev/null)

RECORDING_DIR=""

if [[ -n "$CUSTOM_PATH" ]]; then
    RECORDING_DIR="$CUSTOM_PATH"
else
    RECORDING_DIR="$HOME/Videos" # Use default path
fi

getdate() {
    date '+%Y-%m-%d_%H.%M.%S'
}
getaudiooutput() {
    local sink
    sink=$(pactl get-default-sink) || return 1
    [[ -n "$sink" ]] || return 1
    printf '%s.monitor\n' "$sink"
}
getactivemonitor() {
    hyprctl monitors -j | jq -r '.[] | select(.focused == true) | .name'
}

mkdir -p "$RECORDING_DIR"
cd "$RECORDING_DIR" || exit

# parse --region <value> without modifying $@ so other flags like --fullscreen still work
ARGS=("$@")
MANUAL_REGION=""
SOUND_FLAG=0
FULLSCREEN_FLAG=0
OUTPUT=""
for ((i=0;i<${#ARGS[@]};i++)); do
    if [[ "${ARGS[i]}" == "--region" ]]; then
        if (( i+1 < ${#ARGS[@]} )); then
            MANUAL_REGION="${ARGS[i+1]}"
        else
            notify-send "Recording cancelled" "No region specified for --region" -a 'Recorder' & disown
            exit 1
        fi
    elif [[ "${ARGS[i]}" == "--sound" ]]; then
        SOUND_FLAG=1
    elif [[ "${ARGS[i]}" == "--fullscreen" ]]; then
        FULLSCREEN_FLAG=1
    elif [[ "${ARGS[i]}" == "--output" ]]; then
        (( i+1 < ${#ARGS[@]} )) || exit 1
        OUTPUT="${ARGS[i+1]}"
        ((i++))
    fi
done

if pgrep wf-recorder > /dev/null; then
    notify-send "Recording Stopped" "Stopped" -a 'Recorder' &
    pkill -INT -x wf-recorder
else
    filename="./recording_$(getdate).mp4"
    recorder_args=(--pixel-format yuv420p -f "$filename")
    if [[ $SOUND_FLAG -eq 1 ]]; then
        if ! audio_source=$(getaudiooutput); then
            notify-send "Recording failed" "Could not find the default audio output" -a 'Recorder'
            exit 1
        fi
        recorder_args+=(--audio="$audio_source" --audio-codec aac)
    fi
    if [[ $FULLSCREEN_FLAG -eq 1 ]]; then
        recorder_args+=(-o "${OUTPUT:-$(getactivemonitor)}")
    else
        # If a manual region was provided via --region, use it; otherwise run slurp as before.
        if [[ -n "$MANUAL_REGION" ]]; then
            region="$MANUAL_REGION"
        else
            if ! region="$(slurp 2>&1)"; then
                notify-send "Recording cancelled" "Selection was cancelled" -a 'Recorder' & disown
                exit 1
            fi
        fi

        recorder_args+=(--geometry "$region")
    fi
    notify-send "Starting recording" "${filename#./}" -a 'Recorder' & disown
    wf-recorder "${recorder_args[@]}"
fi
