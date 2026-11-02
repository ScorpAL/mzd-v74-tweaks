#!/bin/sh
# RAM-only singleton and explicit replug request. Never restart an active worker.
MZD_SESSION_DIR=/tmp/mzd-installer-session
mzd_session_stamp() {
    case "$1" in ''|*[!0-9]*) return 1;; esac
    # The shell process name has no spaces; start time prevents PID reuse.
    awk '{print $22}' "/proc/$1/stat" 2>/dev/null
}
mzd_session_claim() {
    session_stamp=$(mzd_session_stamp "$$") || return 1
    if ! mkdir "$MZD_SESSION_DIR" 2>/dev/null; then
        [ -d "$MZD_SESSION_DIR" ] && [ ! -L "$MZD_SESSION_DIR" ] || return 1
        # Serialize inspection/reclamation; an incomplete publisher is left alone.
        mkdir "$MZD_SESSION_DIR/check" 2>/dev/null || return 1
        if [ ! -f "$MZD_SESSION_DIR/owner" ] || [ -L "$MZD_SESSION_DIR/owner" ]; then
            rmdir "$MZD_SESSION_DIR/check"; return 1
        fi
        session_pid=$(sed -n '1p' "$MZD_SESSION_DIR/owner")
        session_old_stamp=$(sed -n '2p' "$MZD_SESSION_DIR/owner")
        session_state=$(sed -n '3p' "$MZD_SESSION_DIR/owner")
        if [ -n "$session_old_stamp" ] && [ "$(mzd_session_stamp "$session_pid")" = "$session_old_stamp" ]; then
            case "$session_state" in /tmp/cmu-installer.*) ;; *) rmdir "$MZD_SESSION_DIR/check";return 1;; esac
            if [ -d "$session_state" ] && [ ! -L "$session_state" ] &&
                [ ! -e "$session_state/ui-close" ] && [ ! -e "$session_state/ui-closing" ]; then
                printf '%s\n' "$HERE" > "$session_state/usb-root.next" &&
                    mv "$session_state/usb-root.next" "$session_state/usb-root" &&
                    : > "$session_state/ui-refocus-request"
                session_code=$?
            else session_code=1; fi
            rmdir "$MZD_SESSION_DIR/check"
            [ "$session_code" = 0 ] || return 1
            printf 'Requested existing installer visibility and focus.\n'
            return 2
        fi
        rm -f "$MZD_SESSION_DIR/owner" && rmdir "$MZD_SESSION_DIR/check" && rmdir "$MZD_SESSION_DIR" || return 1
        mkdir "$MZD_SESSION_DIR" 2>/dev/null || return 1
    fi
    printf '%s\n%s\n%s\n' "$$" "$session_stamp" "$STATE" > "$MZD_SESSION_DIR/owner.next" &&
        mv "$MZD_SESSION_DIR/owner.next" "$MZD_SESSION_DIR/owner" || return 1
    MZD_SESSION_OWNED=1
    printf '%s\n' "$HERE" > "$STATE/usb-root"
}
mzd_session_release() {
    [ "${MZD_SESSION_OWNED:-0}" = 1 ] || return 0
    [ "$(sed -n '1p' "$MZD_SESSION_DIR/owner" 2>/dev/null)" = "$$" ] || return 1
    rm -f "$MZD_SESSION_DIR/owner" && rmdir "$MZD_SESSION_DIR"
}
