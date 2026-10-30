#!/bin/sh
# Original CMU shell and awk, with private RAM configuration only.
set -eu
ROOT=/experiment/package
. "$ROOT/lib/manifest.sh"
. "$ROOT/lib/settings.sh"
manifest="$ROOT/tweaks/settings-example/manifest.conf"
mzd_manifest_load "$manifest"
file=$(mktemp /tmp/original-settings.XXXXXX)
trap 'rm -f "$file"' 0
mzd_settings_normalize "$manifest" log_limit_mb=35 compress=false profile=large > "$file"
echo SETTINGS_NORMALIZED
mzd_settings_check "$manifest" "$file"
echo SETTINGS_CHECKED
MZD_SETTINGS_FILE=$file; export MZD_SETTINGS_FILE
[ "$(mzd_setting log_limit_mb)" = 35 ]
[ "$(mzd_setting compress)" = false ]
[ "$(mzd_setting profile)" = large ]
echo SETTINGS_VALUES_READ
for invalid in log_limit_mb=21 log_limit_mb=2147483648 profile=unknown compress=no; do
    if mzd_settings_normalize "$manifest" "$invalid" >/dev/null 2>&1; then echo "INVALID_VALUE_ACCEPTED=$invalid"; exit 1; fi
    echo "REFUSED=$invalid"
done
echo SETTINGS_LIMITS_PASSED
if mzd_settings_normalize "$manifest" compress=true compress=false >/dev/null 2>&1; then exit 1; fi
if mzd_settings_normalize "$manifest" 'profile=stock
compress=true' >/dev/null 2>&1; then exit 1; fi
echo SETTINGS_DUPLICATES_PASSED
printf 'log_limit_mb=35\n' > "$file"
if mzd_settings_check "$manifest" "$file" >/dev/null 2>&1; then exit 1; fi
echo ORIGINAL_SETTINGS_PASSED
