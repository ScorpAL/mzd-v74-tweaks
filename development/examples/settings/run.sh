#!/bin/sh
# Copy this complete folder into usb/tweaks/settings-example to run it.
set -u
HERE=$(CDPATH= cd "$(dirname "$0")" && pwd) || exit 1
case "${1:-}" in
    ''|-h|--help) printf 'Usage: sh run.sh <run|status> [key=value ...]\n'; exit 0 ;;
    run|status) action=$1; shift ;;
    *) printf 'Unsupported action.\n' >&2; exit 1 ;;
esac
. "$HERE/../../lib/manifest.sh" && . "$HERE/../../lib/settings.sh" || exit 1
mzd_manifest_load "$HERE/manifest.conf" || exit 1
[ -r /jci/version.ini ] || { printf 'Cannot read firmware version.\n' >&2; exit 1; }
if ! awk -v expected="JCI_SW_VER=\"MAZ_CMU-150_$FIRMWARE\"" '$0==expected {found=1} END {exit !found}' /jci/version.ini; then
    [ "$action" != status ] || printf 'unavailable\n'
    printf 'Requires firmware %s.\n' "$FIRMWARE" >&2
    [ "$action" = status ]; exit $?
fi
if [ "$action" = status ]; then
    [ "$#" = 0 ] || exit 1
    printf 'uninstalled\n'; exit 0
fi
if [ -z "${MZD_SETTINGS_FILE:-}" ]; then
    temporary=$(mktemp /tmp/mzd-settings-example.XXXXXX) || exit 1
    trap 'rm -f "$temporary"' 0
    mzd_settings_normalize "$HERE/manifest.conf" "$@" > "$temporary" || exit 1
    MZD_SETTINGS_FILE=$temporary; export MZD_SETTINGS_FILE
else
    [ "$#" = 0 ] || { printf 'Values already supplied by the controller.\n' >&2; exit 1; }
fi
mzd_settings_check "$HERE/manifest.conf" "$MZD_SETTINGS_FILE" || exit 1
printf 'Effective settings (no CMU changes):\n'
printf 'Log storage limit: %s MB\n' "$(mzd_setting log_limit_mb)"
printf 'Compress old logs: %s\n' "$(mzd_setting compress)"
printf 'Profile: %s\n' "$(mzd_setting profile)"
