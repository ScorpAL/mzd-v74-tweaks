#!/bin/sh
# Copy a snapshot of running logs to the originating USB, without changing rotation.
set -u
SELF=$(readlink -f "$0") || exit 1
HERE=$(dirname "$SELF")
ROOT=$(CDPATH= cd "$HERE/../.." && pwd) || exit 1
EXPORT_TOOLS='wc sed mktemp'
mzd_export_ready() {
    first=$(find "$APP" -type f | sed -n '1p')
    [ -n "$first" ] || { printf 'No running log files are available.\n' >&2; return 2; }
}
mzd_export_run() {
    find "$APP" -type f > "$EXPORT_PARTIAL/source-files.txt" || return 1
    total=$(wc -l < "$EXPORT_PARTIAL/source-files.txt" | awk '{print $1}')
    [ "$total" -gt 0 ] || { printf 'No running log files found.\n' >&2; return 1; }
    mkdir "$EXPORT_PARTIAL/logs" || return 1
    count=0
    while IFS= read -r file; do
        relative=${file#"$APP"/}
        mkdir -p "$EXPORT_PARTIAL/logs/$(dirname "$relative")" || return 1
        cp "$file" "$EXPORT_PARTIAL/logs/$relative" >> "$EXPORT_PARTIAL/run.log" 2>&1 || {
            printf 'Cannot copy a running log (it may have rotated): %s\n' "$file" >&2; return 1;
        }
        count=$((count + 1))
        mzd_export_progress "$count" "$total" 'Copying running log files'
    done < "$EXPORT_PARTIAL/source-files.txt"
    printf 'Copied %s log files.\n' "$count"
}
. "$ROOT/lib/export.sh" || exit 1
mzd_export_main "$@"
