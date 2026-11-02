#!/bin/sh
# Date and time of the car for log/report names, log headers and file dates.
# Details and the facts behind this file: development/CMU-time.md.
#
# Why this is needed:
#   - Nothing on the CMU sets the Linux clock: `date` counts from 1970-01-01 at
#     every power-on. It is fine for durations, never for dates.
#   - The RTC (/sys/class/rtc/rtc0/since_epoch) holds the real UTC time once the
#     car's clock was set. A value before 2022-08-01 means it was reset (battery).
#   - com.jci.BLM_TIME.GetClock (D-Bus) gives the time shown on the car's clock:
#     its LOCAL time. Local minus RTC is the car's zone offset (zone plus DST).
#     The service may not answer in the first seconds after power-on.
# This file only reads: it never sets a clock and calls no D-Bus method that
# changes anything.
#
# What each function does (example: 16:49:39 UTC, car zone +4:00, 228 s after power-on):
#   mzd_datetime_init      asks the car for its zone offset, at most about 2 s and at
#                          most once: it exports MZD_DATETIME_ASKED=1 and, when known,
#                          MZD_DATETIME_OFFSET (14400). Child processes (the workers the
#                          launcher starts) inherit both and never ask again.
#   mzd_datetime_snapshot  calls mzd_datetime_init and reads the time once into
#                          MZD_DATETIME_MODE (local, utc or none), MZD_DATETIME_UTC,
#                          MZD_DATETIME_LOCAL and MZD_DATETIME_UPTIME. Call it in the main
#                          shell (not in $(...)) before a name and its Start line, so that
#                          both show the same second.
#   mzd_datetime_name      prints a name part (from the snapshot, else the time now):
#                            20261101-204939   car's local time
#                            20261101-164939Z  UTC; the car's zone is not known yet
#                            nodate-u228       no real date; seconds since power-on
#   mzd_datetime_start     prints the line for the top of a log, which ties its
#                          uptime stamps (00:03:48 ...) to the real time:
#                            Start: 2026-11-01 20:49:39 local (UTC 16:49:39, zone +4:00), 228 s after power-on
#   mzd_datetime_touch [-r] PATH...
#                          gives finished files and folders the car's local time NOW as
#                          their date (e.g. 2026-11-01 20:51:02), because the USB stick's
#                          FAT stores local time. Only the given paths; with -r also all
#                          below them (only for our own log folders, never for copies).
#                          Does nothing when the local time is not known.
# Helpers named mzd_datetime_* without a description above are internal.

# Seconds since power-on, whole seconds; 0 if unreadable.
mzd_datetime_uptime() (
    mt_up=$(cut -d. -f1 /proc/uptime 2>/dev/null)
    case "$mt_up" in ''|*[!0-9]*) mt_up=0 ;; esac
    printf '%s\n' "$mt_up"
)

# Real UTC seconds from the RTC. Fails (prints nothing) when unreadable or reset.
mzd_datetime_rtc() (
    mt_rtc=$(cat /sys/class/rtc/rtc0/since_epoch 2>/dev/null)
    case "$mt_rtc" in ''|*[!0-9]*) exit 1 ;; esac
    # At most 10 digits keeps the 32-bit shell arithmetic safe; before 2022-08-01 = reset.
    [ "${#mt_rtc}" -le 10 ] && [ "$mt_rtc" -ge 1659312000 ] || exit 1
    printf '%s\n' "$mt_rtc"
)

# A usable offset in seconds: whole quarter hours between -14:00 and +14:00.
mzd_datetime_offset_ok() (
    case "$1" in ''|-|*[!0-9-]*|?*-*|-0*|0?*) exit 1 ;; esac
    [ "${#1}" -le 6 ] && [ "$1" -ge -50400 ] && [ "$1" -le 50400 ] && [ "$(($1 % 900))" = 0 ]
)

# Asks GetClock for the local time and prints its offset to the RTC.
mzd_datetime_query() (
    # Without a real date an offset is of no use: do not ask.
    mt_rtc=$(mzd_datetime_rtc) || exit 1
    # Never wait without a limit: no timeout, no question.
    command -v timeout >/dev/null 2>&1 && command -v dbus-send >/dev/null 2>&1 || exit 1
    # BusyBox syntax is "timeout -t N". The outer 2>/dev/null also hides the
    # shell's "Terminated" note when the time limit is reached.
    mt_reply=$( { timeout -t 2 dbus-send --address=unix:path=/tmp/dbus_hmi_socket --reply-timeout=1500 \
        --print-reply --dest=com.jci.BLM_TIME /com/jci/BLM_TIME com.jci.BLM_TIME.GetClock; } 2>/dev/null) || exit 1
    # The reply: uint32 hours, uint32 minutes, uint32 u32Timestamp (local time
    # as epoch seconds), uint64. Take the third uint32.
    mt_local=$(printf '%s\n' "$mt_reply" | awk '$1 == "uint32" && ++n == 3 {print $2; exit}')
    case "$mt_local" in ''|*[!0-9]*) exit 1 ;; esac
    [ "${#mt_local}" -le 10 ] || exit 1
    # Round to 15 minutes: the RTC was read a moment earlier, and "Adjust Time"
    # in the car's settings sets minutes only.
    mt_offset=$((mt_local - mt_rtc)); mt_sign=1
    [ "$mt_offset" -ge 0 ] || { mt_sign=-1; mt_offset=$((-mt_offset)); }
    mt_offset=$(( (mt_offset + 450) / 900 * 900 * mt_sign ))
    mzd_datetime_offset_ok "$mt_offset" || exit 1
    printf '%s\n' "$mt_offset"
)

mzd_datetime_init() {
    # An offset inherited from the launcher is used as it is (when valid).
    if mzd_datetime_offset_ok "${MZD_DATETIME_OFFSET:-}"; then export MZD_DATETIME_OFFSET; return 0; fi
    MZD_DATETIME_OFFSET=
    # Ask at most once, child processes included: a silent service costs 2 s only once.
    [ -z "${MZD_DATETIME_ASKED:-}" ] || return 0
    MZD_DATETIME_ASKED=1; export MZD_DATETIME_ASKED
    MZD_DATETIME_OFFSET=$(mzd_datetime_query) || MZD_DATETIME_OFFSET=
    [ -z "$MZD_DATETIME_OFFSET" ] || export MZD_DATETIME_OFFSET
    return 0
}

# Reads the time now. Prints "MODE UTC LOCAL UPTIME"; MODE is local, utc (zone
# unknown) or none (no date). Uses the offset known so far; never asks D-Bus.
mzd_datetime_read() (
    mt_up=$(mzd_datetime_uptime)
    if mt_rtc=$(mzd_datetime_rtc); then
        if mzd_datetime_offset_ok "${MZD_DATETIME_OFFSET:-}"; then
            printf 'local %s %s %s\n' "$mt_rtc" "$((mt_rtc + MZD_DATETIME_OFFSET))" "$mt_up"
        else
            printf 'utc %s %s %s\n' "$mt_rtc" "$mt_rtc" "$mt_up"
        fi
    else
        printf 'none 0 0 %s\n' "$mt_up"
    fi
)

mzd_datetime_snapshot() {
    mzd_datetime_init
    mzd_datetime_now=$(mzd_datetime_read)
    read -r MZD_DATETIME_MODE MZD_DATETIME_UTC MZD_DATETIME_LOCAL MZD_DATETIME_UPTIME <<EOF
$mzd_datetime_now
EOF
    unset mzd_datetime_now
}

# The snapshot if there is one, else the time now (the same four fields).
mzd_datetime_current() (
    if [ -n "${MZD_DATETIME_MODE:-}" ]; then
        printf '%s %s %s %s\n' "$MZD_DATETIME_MODE" "$MZD_DATETIME_UTC" "$MZD_DATETIME_LOCAL" "$MZD_DATETIME_UPTIME"
    else
        mzd_datetime_read
    fi
)

mzd_datetime_name() (
    # shellcheck disable=SC2046 # split on purpose: MODE UTC LOCAL UPTIME
    set -- $(mzd_datetime_current)
    case "$1" in
        local) date -u -d "@$3" +%Y%m%d-%H%M%S ;;
        utc) date -u -d "@$2" +%Y%m%d-%H%M%SZ ;;
        *) printf 'nodate-u%s\n' "$4" ;;
    esac
)

mzd_datetime_start() (
    # shellcheck disable=SC2046 # split on purpose: MODE UTC LOCAL UPTIME
    set -- $(mzd_datetime_current)
    case "$1" in
        local)
            # The zone as on a clock: +4:00, -3:30, +5:45.
            mt_offset=$(($3 - $2)); mt_sign=+
            [ "$mt_offset" -ge 0 ] || { mt_sign=-; mt_offset=$((-mt_offset)); }
            mt_zone=$(printf '%s%d:%02d' "$mt_sign" "$((mt_offset / 3600))" "$((mt_offset % 3600 / 60))")
            printf 'Start: %s local (UTC %s, zone %s), %s s after power-on\n' \
                "$(date -u -d "@$3" '+%Y-%m-%d %H:%M:%S')" "$(date -u -d "@$2" +%H:%M:%S)" "$mt_zone" "$4" ;;
        utc)
            printf 'Start: %s UTC (car zone not known yet), %s s after power-on\n' \
                "$(date -u -d "@$2" '+%Y-%m-%d %H:%M:%S')" "$4" ;;
        *) printf 'Start: no date (car clock not set), %s s after power-on\n' "$4" ;;
    esac
)

mzd_datetime_touch() (
    mt_recursive=
    [ "${1:-}" != -r ] || { mt_recursive=1; shift; }
    # A new reading: the dates show when the files were finished, not the start.
    # shellcheck disable=SC2046 # split on purpose: MODE UTC LOCAL UPTIME
    set -- $(mzd_datetime_read) "$@"
    # UTC would show hours off in Windows/macOS: set dates only with the local time.
    [ "$1" = local ] || exit 0
    mt_stamp=$(date -u -d "@$3" '+%Y-%m-%d %H:%M:%S') || exit 1
    shift 4
    # FAT keeps the digits as written. TZ is not set on the CMU; TZ=UTC0 makes touch
    # read them the same way everywhere. Links are skipped (touch would change their
    # target), and so are missing paths (touch would create them).
    mt_result=0
    for mt_path in "$@"; do
        [ -e "$mt_path" ] && [ ! -L "$mt_path" ] || continue
        if [ -n "$mt_recursive" ]; then
            # BusyBox 1.19.2 runs "{} +" like "{} \;" (findutils/find.c:1030): one touch per file.
            TZ=UTC0 find "$mt_path" ! -type l -exec touch -d "$mt_stamp" {} + || mt_result=1
        else
            TZ=UTC0 touch -d "$mt_stamp" "$mt_path" || mt_result=1
        fi
    done
    exit "$mt_result"
)
