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
      [ -d "$path" ] && [ ! -L "$path" ] && [ -f "$path/manifest.json" ] || continue
      id=${path##*/}
      valid_id "$id" || continue
      printf '%s\n' "$id"
    done ;;
  manifest|action)
    [ "$#" -ge 2 ] && valid_id "$2" || fail 'Invalid tweak folder.'
    TWEAK="$HERE/tweaks/$2"
    [ -d "$TWEAK" ] && [ ! -L "$TWEAK" ] || fail 'Tweak folder is missing or is a symbolic link.'
    if [ "$1" = manifest ]; then
      [ -f "$TWEAK/manifest.json" ] && [ ! -L "$TWEAK/manifest.json" ] || fail 'Manifest is missing or is a symbolic link.'
      cat "$TWEAK/manifest.json"
    else
      [ "$#" = 3 ] || fail 'Expected tweak and action.'
      case "$3" in install|uninstall|status|run) ;; *) fail 'Unsupported action.' ;; esac
      [ -f "$TWEAK/run.sh" ] && [ ! -L "$TWEAK/run.sh" ] || fail 'Tweak run.sh is missing or is a symbolic link.'
      # No string evaluation or shell command concatenation. Preserve the
      # worker's stdout, stderr and exit code, including critical exit code 2.
      cd "$TWEAK" || exit 1
      exec /bin/sh "$TWEAK/run.sh" "$3"
    fi ;;
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
