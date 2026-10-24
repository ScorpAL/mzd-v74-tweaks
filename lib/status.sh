#!/bin/sh
# Contract v1: successful inspection returns one state, with reasons on stderr.
# All probes use private RAM copies. Never enter the USB/report/mount lifecycle.
mzd_status_emit() {
    [ -z "${2:-}" ] || printf '%s\n' "$2" >&2
    printf '%s\n' "$1"
}

# A complete reverse probe has failed. An individually reversible hunk proves
# that part of this tweak is present; do not label that partial install absent.
mzd_status_partial() (
    mkdir "$MZD_REPORT/hunks" || exit 1
    awk -v dir="$MZD_REPORT/hunks" '
      /^@@ / {n++; file=dir "/" n ".patch"; print "--- target.data\n+++ target.data" > file}
      n {print > file}
    ' "$1" || exit 1
    for part in "$MZD_REPORT/hunks/"*.patch; do
        [ -f "$part" ] || continue
        cp "$APP" "$MZD_REPORT/hunks/target.data" || exit 1
        if (cd "$MZD_REPORT/hunks" && patch -N -R -p0 -i "$part" < /dev/null) >/dev/null 2>&1; then
            exit 0
        fi
    done
    exit 1
)

# Metadata lists are mirrored by these worker constants. CI checks parity.
# A bounded dependency trail also protects direct CLI calls from recursion.
mzd_status_dependencies() (
    trail=${MZD_DEPENDENCY_TRAIL:-:}
    case "$trail" in *":$ID:"*) printf 'Dependency cycle involving %s.\n' "$ID" >&2; exit 1 ;; esac
    [ "${#trail}" -lt 512 ] || { printf 'Dependency chain is too long.\n' >&2; exit 1; }
    MZD_DEPENDENCY_TRAIL="$trail$ID:"; export MZD_DEPENDENCY_TRAIL
    if command -v mzd_check_prerequisites >/dev/null 2>&1; then
        mzd_check_prerequisites >&2 || exit 1
    fi
    for dependency in $REQUIRES; do
        case "$dependency" in ''|*[!a-z0-9-]*) printf 'Invalid dependency ID.\n' >&2; exit 1 ;; esac
        result=$(sh "$ROOT/tweaks/$dependency/run.sh" status 2>/dev/null) || result=error
        [ "$result" = installed ] || { printf 'Requires installed tweak: %s.\n' "$dependency" >&2; exit 1; }
    done
    for conflict in $CONFLICTS; do
        case "$conflict" in ''|*[!a-z0-9-]*) printf 'Invalid conflict ID.\n' >&2; exit 1 ;; esac
        result=$(sh "$ROOT/tweaks/$conflict/run.sh" status 2>/dev/null) || result=error
        case "$result" in
            uninstalled) ;;
            *) printf 'Conflicting or unresolved tweak: %s.\n' "$conflict" >&2; exit 1 ;;
        esac
    done
)

mzd_read_status() (
    ACTION=status
    [ ! -e "$LOCK" ] || mzd_fail 'Target is busy; retry status after the other operation.'
    mzd_require_assets "$SELF" "$HERE/manifest.json" "$PATCH_FILE" || exit 1
    [ -r /jci/version.ini ] || mzd_fail 'Cannot read the firmware version.'
    if ! mzd_line_is "JCI_SW_VER=\"MAZ_CMU-150_$FIRMWARE\"" /jci/version.ini; then
        mzd_status_emit unavailable "Requires firmware $FIRMWARE."; exit 0
    fi
    if [ ! -f "$APP" ] || [ -L "$APP" ]; then
        if [ "$ID" = ssh ] && [ -e "$SERVICE/enabled" ]; then
            mzd_status_emit broken 'SSH is enabled but its startup target is missing or invalid.'
        else
            mzd_status_emit unavailable 'The supported target file is missing or is a symbolic link.'
        fi
        exit 0
    fi
    [ -r "$APP" ] || mzd_fail 'Cannot read the target file.'
    MZD_REPORT=$(mktemp -d /tmp/mzd-status.XXXXXX) || exit 1
    trap 'rm -rf "$MZD_REPORT"' 0
    trap 'exit 130' INT
    trap 'exit 143' TERM
    STATUS_PATCH=$PATCH_FILE
    mode=normal
    [ "$ID" != ssh ] || mode=additive
    if mzd_patch_prepare "$APP" "$STATUS_PATCH" "$ORIGINAL" "$MZD_REPORT/target" "$mode" > "$MZD_REPORT/probe.log" 2>&1; then
        state=$(mzd_patch_state "$MZD_REPORT/target") || exit 1
    else
        # Only a completed forward/reverse inspection proves incompatibility.
        # I/O/tool failures are inspection errors, never successful states.
        if ! grep -q 'Patch state is unknown, partial or ambiguous' "$MZD_REPORT/probe.log"; then
            cat "$MZD_REPORT/probe.log" >&2; exit 1
        fi
        if mzd_status_partial "$STATUS_PATCH"; then
            state=broken; reason='Only part of this tweak is present; automatic changes are disabled.'
        else
            state=unavailable; reason='The target file does not match a supported patch state.'
        fi
    fi
    [ ! -e "$LOCK" ] && cmp -s "$APP" "$MZD_REPORT/target/before.data" ||
        mzd_fail 'Target changed during status inspection; retry status.'
    if [ "$ID" = ssh ]; then
        if [ "$state" = installed ]; then
            if ! ssh_hook_ok; then
                state=broken; reason='The SSH startup hook is duplicated or incomplete.'
            elif ! ssh_payload_ok; then
                state=broken; reason='SSH hook is present but its service files are missing or changed.'
            elif [ ! -f "$SERVICE/enabled" ] || [ -L "$SERVICE/enabled" ] || ! mzd_line_is enabled "$SERVICE/enabled"; then
                state=broken; reason='SSH hook is present but its enabled marker is missing or invalid.'
            fi
        elif [ -e "$SERVICE/enabled" ] || [ -L "$SERVICE/enabled" ]; then
            state=broken; reason='SSH payload is enabled but its startup hook is missing or incompatible.'
        fi
    fi
    if [ "$state" = installed ] || [ "$state" = uninstalled ]; then
        if [ -f "$APP.org" ] && [ ! -r "$APP.org" ]; then
            mzd_fail 'Cannot read the original backup.'
        fi
        if ! mzd_patch_validate_backup "$MZD_REPORT/target" 2> "$MZD_REPORT/backup-reason"; then
            reason=$(cat "$MZD_REPORT/backup-reason")
            if [ "$state" = installed ]; then state=broken; else state=unavailable; fi
        fi
    fi
    if [ "$state" = installed ] || [ "$state" = uninstalled ]; then
        if ! mzd_status_dependencies 2> "$MZD_REPORT/prerequisites.txt"; then
            reason=$(cat "$MZD_REPORT/prerequisites.txt")
            if [ "$state" = installed ]; then state=broken; else state=unavailable; fi
        fi
    fi
    mzd_status_emit "$state" "${reason:-}"
)

mzd_action_preflight() (
    scratch=$(mktemp -d /tmp/mzd-preflight.XXXXXX) || exit 1
    trap 'rm -rf "$scratch"' 0
    trap 'exit 130' INT
    trap 'exit 143' TERM
    state=$(mzd_read_status 2> "$scratch/reason") || { cat "$scratch/reason" >&2; exit 1; }
    case "$state" in
        installed|uninstalled) exit 0 ;;
        unavailable|broken) cat "$scratch/reason" >&2; printf 'Action refused: %s.\n' "$state" >&2; exit 1 ;;
        *) printf 'Invalid status response; action refused.\n' >&2; exit 1 ;;
    esac
)
