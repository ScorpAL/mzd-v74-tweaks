#!/bin/sh
# Small shell-side adapter. The tweak owns all patch and status logic.
set -u
SELF=$(readlink -f "$0") || exit 1
HERE=$(dirname "$SELF")
fail() { printf '%s\n' "$*" >&2; exit 1; }
valid_id() { case "$1" in ''|*[!a-zA-Z0-9_-]*) return 1 ;; esac; }
case "${1:-}" in
  list)
    for path in "$HERE/tweaks/"*; do
      [ -d "$path" ] && [ ! -L "$path" ] && [ -f "$path/manifest.conf" ] || continue
      id=${path##*/}
      valid_id "$id" || continue
      printf '%s\n' "$id"
    done ;;
  manifest|action)
    [ "$#" -ge 2 ] && valid_id "$2" || fail 'Invalid tweak folder.'
    TWEAK="$HERE/tweaks/$2"
    [ -d "$TWEAK" ] && [ ! -L "$TWEAK" ] || fail 'Tweak folder is missing or is a symbolic link.'
    if [ "$1" = manifest ]; then
      [ -f "$TWEAK/manifest.conf" ] && [ ! -L "$TWEAK/manifest.conf" ] || fail 'Manifest is missing or is a symbolic link.'
      library="$HERE/lib/manifest.sh"
      [ -f "$library" ] && [ ! -L "$library" ] && [ -r "$library" ] || fail 'Manifest reader is missing or unreadable.'
      . "$library" || exit 1
      mzd_manifest_load "$TWEAK/manifest.conf" || exit 1
      [ "$ID" = "$2" ] || fail 'Manifest ID does not match its folder.'
      cat "$TWEAK/manifest.conf"
    else
      [ "$#" = 3 ] || fail 'Expected tweak and action.'
      case "$3" in install|uninstall|status|run) ;; *) fail 'Unsupported action.' ;; esac
      [ -f "$TWEAK/run.sh" ] && [ ! -L "$TWEAK/run.sh" ] || fail 'Tweak run.sh is missing or is a symbolic link.'
      # No string evaluation or shell command concatenation. Preserve the
      # worker's stdout, stderr and exit code, including critical exit code 2.
      cd "$TWEAK" || exit 1
      exec /bin/sh "$TWEAK/run.sh" "$3"
    fi ;;
  start-run|job-status|job-output|job-execute)
    . "$HERE/lib/jobs.sh" || exit 1
    case "$1" in
      start-run) [ "$#" = 2 ] || fail 'Expected a tweak ID.'; mzd_job_start "$2" ;;
      job-status) [ "$#" = 2 ] || fail 'Expected a job ID.'; mzd_job_status "$2" ;;
      job-execute) [ "$#" = 3 ] || exit 1; mzd_job_execute "$2" "$3" ;;
      job-output)
        [ "$#" = 3 ] || fail 'Expected job and output stream.'
        mzd_job_path "$2"
        [ -f "$JOB/done" ] || fail 'Job has not completed.'
        case "$3" in stdout|stderr) cat "$JOB/$3" ;; *) fail 'Unknown output stream.' ;; esac ;;
    esac ;;
  event)
    [ -n "${INSTALLER_STATE:-}" ] && [ -d "$INSTALLER_STATE" ] || fail 'Installer session is missing.'
    case "${2:-}" in
      ready) : > "$INSTALLER_STATE/ui-ready" ;;
      close) : > "$INSTALLER_STATE/ui-close" ;;
      note) ;;
      *) fail 'Unsupported installer event.' ;;
    esac
    printf '%s %s %s\n' "$(date +%H:%M:%S)" "$2" "${3:-}" >> "$INSTALLER_LOG/ui.log"
    ;;
  *) fail 'Usage: installer.sh list | manifest ID | action ID ACTION | event EVENT DETAIL' ;;
esac
