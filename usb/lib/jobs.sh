#!/bin/sh
# Asynchronous command jobs let the unchanged serial shell bridge poll progress.
mzd_job_path() {
    [ -n "${INSTALLER_STATE:-}" ] && [ -d "$INSTALLER_STATE" ] || fail 'Installer session is missing.'
    case "$1" in job.*) ;; *) fail 'Invalid job ID.' ;; esac
    case "$1" in *[!a-zA-Z0-9._-]*|*..*) fail 'Invalid job ID.' ;; esac
    JOB="$INSTALLER_STATE/$1"
    [ -d "$JOB" ] && [ ! -L "$JOB" ] || fail 'Job does not exist.'
}
mzd_job_start() {
    valid_id "$1" || fail 'Invalid tweak ID.'
    TWEAK="$HERE/tweaks/$1"
    . "$HERE/lib/manifest.sh" || exit 1
    mzd_manifest_load "$TWEAK/manifest.conf" || exit 1
    [ "$ID" = "$1" ] && [ "$TYPE" = command ] && [ "$PROGRESS" = true ] || fail 'This is not a progress-enabled command.'
    [ -n "${INSTALLER_STATE:-}" ] && [ -d "$INSTALLER_STATE" ] || fail 'Installer session is missing.'
    . "$HERE/lib/settings.sh" || exit 1
    settings_temp=$(mktemp /tmp/mzd-job-settings.XXXXXX) || exit 1
    trap 'rm -f "$settings_temp"' 0
    id=$1; shift
    mzd_settings_normalize "$TWEAK/manifest.conf" "$@" > "$settings_temp" || exit 1
    mkdir "$INSTALLER_STATE/active-job" || fail 'Another command job is running.'
    JOB=$(mktemp -d "$INSTALLER_STATE/job.XXXXXX") || { rmdir "$INSTALLER_STATE/active-job"; exit 1; }
    cp "$settings_temp" "$JOB/settings.conf" && cmp -s "$settings_temp" "$JOB/settings.conf" || { rmdir "$INSTALLER_STATE/active-job"; exit 1; }
    rm -f "$settings_temp"; trap - 0
    token=${JOB##*/}
    printf '%s\n' "$token" > "$INSTALLER_STATE/active-job/token"
    printf '0\n0\nStarting command\n' > "$JOB/progress"
    # Detach all caller streams, including the native bridge's output pipes.
    /bin/sh "$SELF" job-execute "$token" "$id" </dev/null > /dev/null 2>&1 3>&- 4>&- &
    printf '%s\n' "$!" > "$JOB/pid"
    printf '%s\n' "$token"
}
mzd_job_execute() {
    mzd_job_path "$1"; valid_id "$2" || exit 1
    . "$HERE/lib/settings.sh" || exit 1
    mzd_settings_check "$HERE/tweaks/$2/manifest.conf" "$JOB/settings.conf" || exit 1
    MZD_SETTINGS_FILE="$JOB/settings.conf"; export MZD_SETTINGS_FILE
    MZD_PROGRESS_FILE="$JOB/progress"; export MZD_PROGRESS_FILE
    trap ':' INT TERM
    /bin/sh "$HERE/tweaks/$2/run.sh" run > "$JOB/stdout" 2> "$JOB/stderr" &
    worker=$!; printf '%s\n' "$worker" > "$JOB/worker.pid"
    result=1
    while :; do
        wait "$worker"; result=$?
        kill -0 "$worker" 2>/dev/null || break
    done
    printf '%s\n' "$result" > "$JOB/done.tmp"
    mv "$JOB/done.tmp" "$JOB/done"
    if [ "$(cat "$INSTALLER_STATE/active-job/token" 2>/dev/null)" = "$1" ]; then
        rm -f "$INSTALLER_STATE/active-job/token"; rmdir "$INSTALLER_STATE/active-job"
    fi
}
mzd_job_status() {
    mzd_job_path "$1"
    if [ -f "$JOB/done" ]; then
        printf 'done\n'; cat "$JOB/done"
    else
        pid=$(cat "$JOB/pid" 2>/dev/null)
        case "$pid" in ''|*[!0-9]*) fail 'Job process ID is unavailable.' ;; esac
        if kill -0 "$pid" 2>/dev/null; then
            printf 'running\n'; cat "$JOB/progress"
        else
            printf 'done\n2\n'
        fi
    fi
}
