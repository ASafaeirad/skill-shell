#!/usr/bin/env bash
# Render one panel from THIS checkout (usually a worktree) in a throwaway
# Quickshell instance, next to the live `qs -c skill`, and screenshot it.
# See SKILL.md in this directory.
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)
PREFIX=/tmp/skill-preview-

die() { echo "preview: $*" >&2; exit 1; }

usage() {
    cat <<EOF
Usage: $(basename "$0") <command> ...

  start <Type> [--no-open] [--qml FILE]
        Launch a harness that loads modules/widgets/*/<Type>.qml from
        $ROOT and calls open() on it. Prints the harness dir.
        --qml FILE  use FILE as the harness shell.qml instead (full control).
  shot <harness> [namespace|--screen] [out.png]
        Screenshot the harness's largest layer surface (or the one with the
        given WlrLayershell.namespace), falling back to its window.
        --screen captures the whole monitor. Prints the PNG path.
  ipc <harness> <target> <function> [args...]
  log <harness> [-f]
  stop <harness|all>   Kill harness instance(s) and delete the dir.
                       "all" = every harness built from this checkout.
  list                 Running preview harnesses.
EOF
    exit "${1:-0}"
}

harness_pid() {
    qs list -p "$1" -j 2>/dev/null | jq -r '(if type=="array" then .[0] else . end).pid // empty'
}

ensure_shapes() {
    # modules/common/widgets/shapes is a gitlink without .gitmodules, so
    # worktrees get an empty directory. Borrow the main checkout's copy.
    local dir="$ROOT/modules/common/widgets/shapes"
    [[ -n "$(ls -A "$dir" 2>/dev/null)" ]] && return
    local main
    main=$(git -C "$ROOT" worktree list --porcelain | awk '/^worktree /{print $2; exit}')
    [[ -n "$(ls -A "$main/modules/common/widgets/shapes" 2>/dev/null)" ]] ||
        die "shapes/ is empty here and in $main; cannot resolve qs.modules.common.widgets.shapes"
    mkdir -p "$dir"
    cp -r "$main/modules/common/widgets/shapes/." "$dir/"
    echo "preview: populated shapes/ from $main" >&2
}

cmd_start() {
    local type="" open=1 qml=""
    while (($#)); do
        case $1 in
            --no-open) open=0 ;;
            --qml) qml=$2; shift ;;
            -*) die "unknown option $1" ;;
            *) type=$1 ;;
        esac
        shift
    done
    [[ -n $type || -n $qml ]] || usage 1

    ensure_shapes

    local h
    h=$(mktemp -d "${PREFIX}XXXX")
    for f in GlobalStates.qml assets modules scripts services; do
        ln -s "$ROOT/$f" "$h/$f"
    done

    if [[ -n $qml ]]; then
        cp "$qml" "$h/shell.qml"
    else
        local file
        file=$(find "$ROOT/modules/widgets" -name "$type.qml" -print -quit)
        [[ -n $file ]] || die "no $type.qml under modules/widgets"
        local mod=${file#"$ROOT/"}
        mod=$(dirname "$mod")
        echo "$ROOT/$mod" >"$h/.module"

        # Panel subclasses register Hyprland global shortcuts; keep the live
        # shell's keybinds by not registering duplicates from the harness.
        local extra=""
        grep -q '^Panel {' "$file" &&
            extra="hasToggleShortcut: false; hasOpenCloseShortcuts: false;"
        local oncomplete=""
        ((open)) && oncomplete="Component.onCompleted: open()"

        cat >"$h/shell.qml" <<EOF
//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000
import QtQuick
import Quickshell
import qs.modules.common
import qs.${mod//\//.}

ShellRoot {
    LazyLoader {
        active: Config.ready
        component: $type { $extra $oncomplete }
    }
}
EOF
    fi

    qs -p "$h" -d >"$h/.launch.log" 2>&1 || true
    if grep -q 'ERROR' "$h/.launch.log"; then
        grep -E 'ERROR|caused by' "$h/.launch.log" >&2
        qs kill -p "$h" >/dev/null 2>&1 || true
        rm -rf "$h"
        die "harness failed to load"
    fi
    # Let Config load and the surface map before anyone screenshots it.
    sleep 2
    [[ -n $(harness_pid "$h") ]] || die "harness exited; see $h/.launch.log"
    echo "$h"
}

cmd_shot() {
    local h=${1:-}; [[ -d $h ]] || usage 1
    local ns=${2:-} out=${3:-}
    local pid; pid=$(harness_pid "$h")
    [[ -n $pid ]] || die "harness $h is not running"

    [[ -n $out ]] || out="$h/shot-$(date +%H%M%S).png"

    local geom=""
    if [[ $ns == --screen ]]; then
        grim "$out"
    else
        # The harness runs a single panel, so by default take its largest
        # mapped layer surface; a namespace narrows it down.
        geom=$(hyprctl layers -j | jq -r --arg ns "$ns" --argjson pid "$pid" \
            '[.[].levels[][] | select(.pid==$pid and ($ns=="" or .namespace==$ns) and .w>0 and .h>0)]
             | max_by(.w*.h) | select(.) | "\(.x),\(.y) \(.w)x\(.h)"')
        if [[ -z $geom ]]; then
            # FloatingWindow / toplevel instead of a layer surface
            geom=$(hyprctl clients -j | jq -r --argjson pid "$pid" \
                '[.[] | select(.pid==$pid)][0] | select(.)
                 | "\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')
        fi
        [[ -n $geom ]] || die "no mapped surface for pid $pid${ns:+ (namespace $ns)}; is the panel open? try --screen, or: hyprctl layers -j | jq '.[].levels[][] | select(.pid==$pid)'"
        grim -g "$geom" "$out"
    fi
    echo "$out"
}

cmd_ipc() {
    local h=${1:-}; [[ -d $h ]] || usage 1
    shift
    qs -p "$h" ipc call "$@"
}

cmd_log() {
    local h=${1:-}; [[ -d $h ]] || usage 1
    shift
    qs log -p "$h" "$@"
}

cmd_stop() {
    local target=${1:-}; [[ -n $target ]] || usage 1
    local hs=()
    if [[ $target == all ]]; then
        # Only this checkout's harnesses; other agents may have their own.
        shopt -s nullglob
        for h in "$PREFIX"*; do
            [[ $(readlink "$h/modules") == "$ROOT/modules" ]] && hs+=("$h")
        done
    else
        [[ $target == "$PREFIX"* ]] || die "refusing to stop $target (not a preview harness)"
        hs=("$target")
    fi
    for h in "${hs[@]}"; do
        qs kill -p "$h" >/dev/null 2>&1 || true
        rm -rf "$h"
        echo "stopped $h"
    done
}

cmd_list() {
    shopt -s nullglob
    for h in "$PREFIX"*; do
        local pid; pid=$(harness_pid "$h")
        printf '%s\t%s\t%s\n' "$h" "${pid:-dead}" "$(cat "$h/.module" 2>/dev/null || echo custom)"
    done
}

case ${1:-} in
    start | shot | ipc | log | stop | list) c=$1; shift; "cmd_$c" "$@" ;;
    -h | --help | "") usage ;;
    *) usage 1 ;;
esac
