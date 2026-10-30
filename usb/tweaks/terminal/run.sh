#!/bin/sh
# Terminal with full USB keyboard support. A stateless command: "uninstalled" means ready to Run, nothing is installed.
# Run opens the stock Terminal through assets/terminal.sh and waits until it is closed. Nothing is written to the USB drive
# or to the CMU's flash; the temporary files are in RAM and are removed afterwards.
set -u

[ "$#" -le 1 ] || { printf 'Expected one action.\n' >&2; exit 1; }

SELF=$(readlink -f "$0") || exit 1
HERE=$(dirname "$SELF")

case "${1:-}" in
    status|run)
        . "$HERE/../../lib/manifest.sh" || exit 1
        mzd_manifest_load "$HERE/manifest.conf" || exit 1 ;;
esac

: "${MZD_STOCK:=/jci/scripts/run-terminal.sh}"
: "${MZD_IVI:=/usr/bin/ivi-shell}"
: "${MZD_TERMINAL_BIN:=/usr/bin/terminal}"

# Exact line comparison; the CMU's BusyBox grep has no -x.
line_is() { awk -v expected="$1" '$0 == expected {found=1} END {exit !found}' "$2"; }

# Prints "uninstalled" (ready) or "unavailable" with the reason on stderr. Returns 1 only if the inspection itself fails.
# Read only: it looks at what terminal.sh needs, so that a CMU that cannot run it is reported before Run.
terminal_status() {
    if [ ! -r /jci/version.ini ]; then
        printf 'Cannot read firmware version.\n' >&2
        return 1
    fi

    if ! line_is "JCI_SW_VER=\"MAZ_CMU-150_$FIRMWARE\"" /jci/version.ini; then
        printf 'unavailable\n'
        printf 'Requires firmware %s.\n' "$FIRMWARE" >&2
        return 0
    fi

    for tweak_file in "$HERE/assets/terminal.sh" "$HERE/assets/mzd-kbd-bridge.lua" "$HERE/assets/posixcompat.lua"; do
        if [ ! -f "$tweak_file" ] || [ -L "$tweak_file" ]; then
            printf 'unavailable\n'
            printf 'Missing tweak file: %s\n' "${tweak_file##*/}" >&2
            return 0
        fi
    done

    if [ ! -f "$MZD_STOCK" ]; then
        printf 'unavailable\n'
        printf 'The stock Terminal script is missing.\n' >&2
        return 0
    fi

    # The two lines that terminal.sh replaces in the stock script
    for stock_line in 'echo "" > /tmp/root/weston.ini' "export SHELL='/bin/sh'"; do
        if ! line_is "$stock_line" "$MZD_STOCK"; then
            printf 'unavailable\n'
            printf 'The stock Terminal script is not the expected one.\n' >&2
            return 0
        fi
    done

    for program in "$MZD_TERMINAL_BIN" "$MZD_IVI"; do
        if [ ! -x "$program" ]; then
            printf 'unavailable\n'
            printf 'Missing system program: %s\n' "$program" >&2
            return 0
        fi
    done

    if ! command -v lua >/dev/null 2>&1 || ! lua -e 'require("posix")' >/dev/null 2>&1; then
        printf 'unavailable\n'
        printf 'The CMU Lua interpreter or its posix module is missing.\n' >&2
        return 0
    fi

    if ! busybox --list 2>/dev/null | awk '$0 == "script" {found=1} END {exit !found}'; then
        printf 'unavailable\n'
        printf 'BusyBox script (pseudo-terminal) is missing.\n' >&2
        return 0
    fi

    printf 'uninstalled\n'
}

run_terminal() {
    state=$(terminal_status 2>/dev/null) || { printf 'Cannot check the Terminal prerequisites.\n' >&2; exit 1; }
    if [ "$state" != uninstalled ]; then
        terminal_status 2>&1 >/dev/null | sed -n '1p' >&2
        exit 1
    fi

    # autorun.sh exports these for the launcher's own Opera (for example its fixed Wayland surface number). The Terminal
    # must not inherit them.
    unset WAYLAND_IVI_SURFACE_ID OPERA_DIR OPERA_FONTS OPERA_HOME FREETYPE_FONT_SET

    # The launcher is the secondary Opera: when the Terminal is gone it gets the keyboard focus and its screen back.
    MZD_SURFACE=${MZD_SURFACE:-JCI_OPERA_SECONDARY}
    MZD_RETURN_SURFACE=${MZD_RETURN_SURFACE-10}
    export MZD_SURFACE MZD_RETURN_SURFACE

    # The hint is printed first in the Terminal: not everybody knows how to leave it. | starts a new line: the window is
    # about 38 characters wide, so the break is made here rather than in the middle of a word.
    sh "$HERE/assets/terminal.sh" --wait --hold --hint "To exit: type exit + ENTER|or press HOME on controller"
    code=$?

    # Exit code 2 would be reported as a critical failure and block the launcher. Nothing here is critical: every refusal and
    # failure is code 1.
    case "$code" in
        0) printf 'Terminal closed.\n' ;;
        1) printf 'Terminal was closed by its time limit.\n' >&2; exit 1 ;;
        3) printf 'A Terminal is already open.\n' >&2; exit 1 ;;
        4) printf 'Terminal closed, but the launcher screen or the keyboard focus could not be restored.\n' >&2; exit 1 ;;
        *) printf 'The Terminal could not be opened.\n' >&2; exit 1 ;;
    esac
}

case "${1:-}" in
    ''|-h|--help) printf 'Usage: sh run.sh <run|status>\n' ;;
    status) terminal_status ;;
    run) run_terminal ;;
    *) printf 'Unsupported action.\n' >&2; exit 1 ;;
esac
