#!/bin/sh
# Called only after launcher cleanup; never from a tweak worker.
mzd_launcher_restart() {
    [ "$1" = 0 ] && [ -f "$STATE/ui-restart" ] || return 0
    sync || return 1
    reboot || { printf 'CMU restart failed after installer cleanup.\n' >&2; return 1; }
}
