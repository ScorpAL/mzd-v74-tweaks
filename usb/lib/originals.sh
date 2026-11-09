#!/bin/sh
# Immutable per-package originals. Shared targets borrow the first saved baseline.
mzd_originals_capture() (
    stage=$1
    mkdir "$stage/package/originals" || exit 1
    records="$stage/package/originals/records.tsv"
    : > "$records" || exit 1
    budget=$(df -Pk "$MZD_PACKAGE_MOUNT" | awk 'NR==2 {reserve=$2/10;if(reserve<65536)reserve=65536;printf "%.0f",$4-reserve}') || exit 1
    case "$budget" in ''|*[!0-9]*) mzd_package_error 'Cannot reserve original file storage.'; exit 1 ;; esac
    : > "$stage/package/originals/directories.tsv" || exit 1
    tab=$(printf '\t'); index=0
    while IFS="$tab" read -r kind directory; do
        case "$kind" in create|config-file|config-dir) ;; *) continue ;; esac
        while [ ! -e "$directory" ] && [ ! -L "$directory" ]; do
            printf '%s\n' "$directory" >> "$stage/package/originals/directories.tsv" || exit 1
            directory=${directory%/*}; [ -n "$directory" ] || break
        done
    done < "$stage/paths.tsv"
    # A later consumer inherits ownership of shared parents created by the first.
    for other in "$MZD_PACKAGE_STORE"/*; do
        [ -d "$other" ] && [ -f "$other/package/originals/directories.tsv" ] || continue
        mzd_package_check "$other" || exit 1
        awk -F "$tab" 'NR==FNR {if($1=="create" || $1~/^config-/)paths[$2]=1;next}
            {for(p in paths)if(p==$0 || index(p,$0 "/")==1){print;break}}' \
            "$stage/paths.tsv" "$other/package/originals/directories.tsv" >> "$stage/package/originals/directories.tsv" || exit 1
    done
    LC_ALL=C sort -ru "$stage/package/originals/directories.tsv" > "$stage/package/originals/directories.next" &&
        mv "$stage/package/originals/directories.next" "$stage/package/originals/directories.tsv" || exit 1
    while IFS="$tab" read -r kind target; do
        [ "$kind" = patch ] || continue
        index=$((index+1)); original=''; owned=1
        for other in "$MZD_PACKAGE_STORE"/*; do
            [ -d "$other" ] && [ -f "$other/package/originals/records.tsv" ] || continue
            mzd_package_check "$other" || exit 1
            row=$(awk -F "$tab" -v path="$target" '$2==path {print $1 "\t" $3 "\t" $4 "\t" $5}' "$other/package/originals/records.tsv") || exit 1
            [ -n "$row" ] || continue
            saved_ifs=$IFS; IFS="$tab"; set -- $row; IFS=$saved_ifs
            [ "$#" = 4 ] || exit 1
            number=$1; hash=$2; metadata=$3; owned=$4
            [ "$hash" != - ] || { original=absent; break; }
            original="$other/package/originals/file-$number"
            [ -f "$original" ] && [ ! -L "$original" ] && [ "$(md5sum "$original" | cut -d ' ' -f1)" = "$hash" ] || exit 1
            [ "$(stat -c '%a:%u:%g:%Y' "$original")" = "$metadata" ] || exit 1
            break
        done
        if [ -z "$original" ]; then
            if [ -e "$target.org" ] || [ -L "$target.org" ]; then original="$target.org"; owned=0
            elif [ -e "$target" ] || [ -L "$target" ]; then original=$target
            else original=absent; fi
        fi
        if [ "$original" = absent ]; then
            printf '%s\t%s\t-\t-\t0\n' "$index" "$target" >> "$records" || exit 1
        else
            [ -f "$original" ] && [ ! -L "$original" ] || { mzd_package_error 'Original target is not a regular file.'; exit 1; }
            size=$(du -k "$original" | awk 'NR==1 {print $1}') || exit 1
            case "$size" in ''|*[!0-9]*) exit 1 ;; esac
            [ "$budget" -ge "$size" ] || { mzd_package_error 'Not enough persistent space for original files.'; exit 1; }
            budget=$((budget-size))
            cp -a "$original" "$stage/package/originals/file-$index" || exit 1
            hash=$(md5sum "$stage/package/originals/file-$index" | cut -d ' ' -f1) || exit 1
            metadata=$(stat -c '%a:%u:%g:%Y' "$stage/package/originals/file-$index") || exit 1
            printf '%s\t%s\t%s\t%s\t%s\n' "$index" "$target" "$hash" "$metadata" "$owned" >> "$records" || exit 1
        fi
    done < "$stage/paths.tsv"
)

# Byte integrity is covered by package.files; metadata is checked separately.
mzd_originals_validate() (
    entry=$1; tab=$(printf '\t'); index=0
    while IFS="$tab" read -r number target hash metadata owned; do
        index=$((index+1)); [ "$number" = "$index" ] || exit 1
        case "$owned" in 0|1) ;; *) exit 1 ;; esac
        [ "$hash" != - ] || continue
        original="$entry/package/originals/file-$number"
        [ -f "$original" ] && [ ! -L "$original" ] &&
            [ "$(stat -c '%a:%u:%g:%Y' "$original")" = "$metadata" ] || {
                mzd_package_error 'Original file metadata is missing or changed; nothing executed.'; exit 1;
            }
    done < "$entry/package/originals/records.tsv"
)

mzd_originals_cleanup() {
    result=0
    if [ -n "${MZD_ORIGINAL_TEMP:-}" ]; then rm -f "$MZD_ORIGINAL_TEMP" || result=1; fi
    mzd_system_cleanup || result=1
    return "$result"
}

# Called after the saved worker and its uninstalled status have succeeded.
# No content is overwritten: only an exact original can have metadata restored.
mzd_originals_finish() (
    entry=$1
    [ -f "$entry/package/originals/records.tsv" ] || exit 0
    needed=0
    if awk -F "$(printf '\t')" '$3!="-" {found=1} END {exit !found}' "$entry/package/originals/records.tsv"; then needed=1; fi
    while IFS= read -r directory; do
        if [ -d "$directory" ] && [ ! -L "$directory" ]; then needed=1; break; fi
    done < "$entry/package/originals/directories.tsv"
    [ "$needed" = 1 ] || exit 0
    ROOT="$entry/package"; HERE="$ROOT/tweaks/${entry##*/}"
    for library in report system shim; do . "$ROOT/lib/$library.sh" || exit 1; done
    mzd_manifest_load "$HERE/manifest.conf" || exit 1
    ACTION=uninstall; MZD_ORIGINAL_TEMP=''; MZD_ORIGINALS_CLEANUP=1
    mzd_begin "$HERE/run.sh" "$ID" mzd_originals_cleanup
    mzd_system_begin
    tab=$(printf '\t'); index=0
    : > "$MZD_REPORT/originals.tsv" || exit 1
    while IFS="$tab" read -r number target hash metadata owned; do
        index=$((index+1)); [ "$number" = "$index" ] || mzd_fail 'Invalid original file index.'
        awk -F "$tab" -v path="$target" '$1=="patch" && $2==path {found++} END {exit found!=1}' "$entry/paths.tsv" || mzd_fail 'Original file is outside the saved ownership record.'
        shared=0
        for other in "$MZD_PACKAGE_STORE"/*; do
            [ -d "$other" ] && [ "$other" != "$entry" ] || continue
            mzd_package_check "$other" || exit 1
            if awk -F "$tab" -v path="$target" '$1=="patch" && $2==path {found=1} END {exit !found}' "$other/paths.tsv"; then shared=1; break; fi
        done
        [ "$shared" = 0 ] || continue
        if [ "$hash" = - ]; then
            [ ! -e "$target" ] && [ ! -L "$target" ] || mzd_fail 'An originally absent target remains after uninstall.'
            continue
        fi
        original="$entry/package/originals/file-$number"
        mzd_asset_readable "$original" && [ "$(mzd_hash "$original")" = "$hash" ] || mzd_fail 'Saved original is missing or changed.'
        [ "$(stat -c '%a:%u:%g:%Y' "$original")" = "$metadata" ] || mzd_fail 'Saved original metadata changed.'
        case "$owned" in 0|1) ;; *) mzd_fail 'Invalid original backup ownership.' ;; esac
        mzd_asset_readable "$target" || mzd_fail 'Uninstalled target is missing or not a regular file.'
        current=$(mzd_hash "$target") || exit 1
        restore_metadata=0; [ "$current" != "$hash" ] || restore_metadata=1
        if [ -e "$target.org" ] || [ -L "$target.org" ]; then
            mzd_asset_readable "$target.org" && cmp -s "$target.org" "$original" || mzd_fail 'Original backup differs from the saved baseline; nothing deleted.'
        fi
        printf '%s\t%s\t%s\t%s\t%s\n' "$number" "$target" "$restore_metadata" "$current" "$owned" >> "$MZD_REPORT/originals.tsv" || exit 1
    done < "$entry/package/originals/records.tsv"
    if [ -s "$MZD_REPORT/originals.tsv" ]; then
        mzd_system_lock "$LOCK" || exit 1
        if [ -n "${GUI_SERVICE:-}" ]; then mzd_system_lock /tmp/mzd-stage_wifi-tweak.lock || exit 1; fi
        mzd_system_watchdog_disable || exit 1
        while IFS="$tab" read -r number target restore_metadata current owned; do
            original="$entry/package/originals/file-$number"
            mount_point=$(mzd_shim_mount "$target") || exit 1
            mzd_system_remount_rw "$mount_point" || exit 1
            [ "$(mzd_hash "$target")" = "$current" ] || mzd_fail 'Target changed before cleanup.'
            [ "$restore_metadata" = 1 ] || continue
            temporary="$target.mzd-uninstall-$$"
            [ ! -e "$temporary" ] && [ ! -L "$temporary" ] || mzd_fail 'Uninstall temporary already exists.'
            MZD_ORIGINAL_TEMP=$temporary
            cp -a "$original" "$MZD_ORIGINAL_TEMP" && cmp -s "$MZD_ORIGINAL_TEMP" "$original" || exit 1
            sync
            mv -f "$MZD_ORIGINAL_TEMP" "$target" || exit 1
            MZD_ORIGINAL_TEMP=''
            [ "$(stat -c '%a:%u:%g:%Y' "$target")" = "$(stat -c '%a:%u:%g:%Y' "$original")" ] || mzd_fail 'Original metadata could not be restored.'
        done < "$MZD_REPORT/originals.tsv"
        sync
        # Retain every backup until every target and its metadata are verified.
        while IFS="$tab" read -r number target restore_metadata current owned; do
            original="$entry/package/originals/file-$number"
            [ "$(mzd_hash "$target")" = "$current" ] || exit 1
            [ "$owned" = 1 ] || continue
            if [ -e "$target.org" ] || [ -L "$target.org" ]; then
                mzd_asset_readable "$target.org" && cmp -s "$target.org" "$original" || exit 1
                rm -f "$target.org" || exit 1
            fi
        done < "$MZD_REPORT/originals.tsv"
    fi
    if [ -n "${GUI_SERVICE:-}" ]; then
        . "$ROOT/lib/gui-extension.sh" && . "$ROOT/lib/gui-services.sh" || exit 1
        data="$MZD_GUI_USER_DATA/$ID"; keep_data=0
        if [ -n "$CONFIGS" ] && [ "${MZD_PRESERVE_CONFIG:-0}" = 1 ]; then
            . "$ROOT/lib/config-data.sh" || exit 1
            records=$(mzd_config_records "$HERE") || exit 1
            if printf '%s\n' "$records" | awk -F "$tab" -v p="$data" '$3==p || index($3,p "/")==1 || index(p,$3 "/")==1 {found=1} END {exit !found}'; then keep_data=1; fi
        fi
        if [ "$keep_data" = 0 ] && { [ -e "$data" ] || [ -L "$data" ]; }; then
            mzd_gui_data_owned "$data" "$ID" && mzd_package_tree_ok "$data" || mzd_fail 'GUI module data ownership is invalid; nothing deleted.'
            mzd_system_remount_rw "$MZD_PACKAGE_MOUNT" || exit 1
            rm -rf "$data" || exit 1
        fi
    fi
    while IFS= read -r directory; do
        [ -d "$directory" ] && [ ! -L "$directory" ] || continue
        if [ -n "$CONFIGS" ] && [ "${MZD_PRESERVE_CONFIG:-0}" = 1 ]; then
            . "$ROOT/lib/config-data.sh" || exit 1
            records=$(mzd_config_records "$HERE") || exit 1
            if printf '%s\n' "$records" | awk -F "$tab" -v p="$directory" '$3==p || index($3,p "/")==1 {found=1} END {exit !found}'; then continue; fi
        fi
        mount_point=$(mzd_shim_mount "$directory") || exit 1
        mzd_system_remount_rw "$mount_point" || exit 1
        # Never recurse or remove unknown contents, shared data or retained configs.
        rmdir "$directory" 2>/dev/null || :
    done < "$entry/package/originals/directories.tsv"
    MZD_SUCCESS="Original file metadata restored; unused .org backups removed.
Reports: $MZD_REPORT"
)
