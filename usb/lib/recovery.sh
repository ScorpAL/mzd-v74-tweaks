#!/bin/sh
# Explicit recovery of one unmanaged patch target. No adoption or service cleanup.
mzd_recovery_error() { printf 'Restore: %s\n' "$*" >&2; return 1; }
mzd_recovery_owners() (
    case "$APP/" in "$MZD_PACKAGE_STORE/"*) mzd_recovery_error 'Saved package files cannot be restored this way.'; exit 1 ;; esac
    [ ! -e "$MZD_PACKAGE_STORE/$ID" ] && [ ! -L "$MZD_PACKAGE_STORE/$ID" ] || {
        mzd_recovery_error 'This tweak has a saved installation. Use Uninstall or System > Restore originals.'; exit 1;
    }
    for entry in "$MZD_PACKAGE_STORE"/*; do
        [ -e "$entry" ] || [ -L "$entry" ] || continue
        mzd_package_check "$entry" || exit 1
        mzd_package_paths_ok "$entry/paths.tsv" || exit 1
        # Resolve registered aliases as well as the recovery target. Otherwise
        # two different path spellings could refer to the same managed file.
        paths=$(while IFS="$(printf '\t')" read -r kind owned; do
            canonical=$(readlink -f "$owned") && [ -e "$canonical" ] || exit 1
            printf '%s\t%s\n' "$kind" "$canonical" || exit 1
        done < "$entry/paths.tsv") || {
            mzd_recovery_error "Registered paths cannot be verified for saved tweak: ${entry##*/}. Use Uninstall or System > Restore originals."; exit 1;
        }
        printf '%s\n' "$paths" | awk -F "$(printf '\t')" -v target="$APP" '
          {p=$2; if(target==p || index(target,p "/")==1 || index(p,target "/")==1 || target ".org"==p) used=1}
          END {exit used}
        ' || {
            mzd_recovery_error "A saved tweak uses this file: ${entry##*/}. Use Uninstall or System > Restore originals."; exit 1;
        }
    done
)
mzd_recovery_validate() {
    [ "$TYPE" = patch ] && [ -z "$RESET_ENTRYPOINT" ] || {
        mzd_recovery_error 'Single-file recovery is only available for plain file patches.'; return 1;
    }
    mzd_validate_firmware "$FIRMWARE" || return 1
    mzd_asset_readable "$APP" && mzd_asset_readable "$APP.org" || {
        mzd_recovery_error 'A readable target and original .org backup are required.'; return 1;
    }
    mzd_system_path "$APP" || return 1
    case "$APP" in *"$(printf '\t')"*|*'\'*|*'/../'*|*'/./'*) mzd_recovery_error 'Unsupported target path.'; return 1 ;; esac
    [ "$(readlink -f "$APP")" = "$APP" ] && [ "$(readlink -f "$APP.org")" = "$APP.org" ] || {
        mzd_recovery_error 'Target and backup paths must not contain symbolic links.'; return 1;
    }
    # Select the actual deepest mount, never a parent underneath USB/RAM mounts.
    RECOVERY_MOUNT=$(awk -v p="$APP" '
      $3!="rootfs" && ($2=="/" || p==$2 || index(p,$2 "/")==1) {
        if(length($2)>length(best)){best=$2; device=$1; fs=$3}
      }
      END {if(device !~ /^\/dev\/(ffx|mmcblk|mtdblock|ubi|root)/ || fs !~ /^(ext2|ext3|ext4|relfs|ubifs|jffs2)$/)exit 1; print best}
    ' /proc/mounts) || { mzd_recovery_error 'The target is not on a supported internal filesystem.'; return 1; }
    if [ -e "$ROOT/tweaks/$ID/managed-paths.tsv" ]; then
        mzd_asset_readable "$ROOT/tweaks/$ID/managed-paths.tsv" || return 1
        awk -F "$(printf '\t')" -v p="$APP" 'NF!=2 || $1!="patch" || $2!=p {bad=1} END {exit bad || NR!=1}' "$ROOT/tweaks/$ID/managed-paths.tsv" || {
            mzd_recovery_error 'This tweak owns additional paths; use its documented removal procedure.'; return 1;
        }
    fi
    mzd_recovery_owners || return 1
    [ "$(mzd_hash "$APP.org")" = "$ORIGINAL" ] || {
        mzd_recovery_error 'The .org backup does not match the expected firmware original.'; return 1;
    }
    RECOVERY_OBSERVED=$(mzd_hash "$APP")
    case "$RECOVERY_OBSERVED" in ''|*[!0-9a-f]*) return 1 ;; esac
    [ "${#RECOVERY_OBSERVED}" = 32 ] || return 1
    [ "$RECOVERY_OBSERVED" != "$ORIGINAL" ] || {
        mzd_recovery_error 'The target is already the original file.'; return 1;
    }
    # Bind consent to the displayed file AND the expected backup/version, not
    # just its bytes: a USB package may have changed while the dialog was open.
    RECOVERY_TOKEN=$(printf '%s\n' "$ID" "$VERSION" "$FIRMWARE" "$APP" "$ORIGINAL" "$RECOVERY_OBSERVED" | md5sum | cut -d' ' -f1)
    [ "${#RECOVERY_TOKEN}" = 32 ] || return 1
}
mzd_recovery_probe() (
    patch_file="$ROOT/tweaks/$ID/assets/change.patch"
    mzd_asset_readable "$patch_file" || exit 1
    awk '/^--- / {old++; if($0!="--- target.data") bad=1} /^\+\+\+ / {new++; if($0!="+++ target.data") bad=1} END {exit bad || old!=1 || new!=1}' "$patch_file" || exit 1
    scratch=$(mktemp -d /tmp/mzd-recovery.XXXXXX) || exit 1
    trap 'rm -rf "$scratch"' 0
    trap 'exit 1' INT TERM
    mkdir "$scratch/oem" "$scratch/current" || exit 1
    cp "$APP.org" "$scratch/oem/before.data" && cp "$APP" "$scratch/current/before.data" || exit 1
    [ "$(mzd_hash "$scratch/oem/before.data")" = "$ORIGINAL" ] &&
        [ "$(mzd_hash "$scratch/current/before.data")" = "$RECOVERY_OBSERVED" ] || exit 1
    mzd_patch_probe "$scratch/oem" install "$patch_file" || {
        mzd_recovery_error 'This patch cannot be verified against the original backup.'; exit 1;
    }
    [ ! -e "$scratch/oem/probe-error" ] || exit 1
    forward=0; reverse=0
    mzd_patch_probe "$scratch/current" install "$patch_file" && forward=1
    mzd_patch_probe "$scratch/current" uninstall "$patch_file" && reverse=1
    [ ! -e "$scratch/current/probe-error" ] || {
        mzd_recovery_error 'The patch tool failed; recovery is not offered.'; exit 1;
    }
    [ "$forward:$reverse" != 1:0 ] || {
        mzd_recovery_error 'The target supports normal installation; original-file recovery is not needed.'; exit 1;
    }
    cmp -s "$APP" "$scratch/current/before.data" && cmp -s "$APP.org" "$scratch/oem/before.data" || {
        mzd_recovery_error 'Target or backup changed during inspection.'; exit 1;
    }
)
mzd_recovery_run() (
    # The caller restores USB mode after the report lifecycle has finished writing.
    ACTION=restore-original
    mzd_begin "$SELF" "restore-file-$ID" mzd_restore_cleanup
    mzd_system_begin
    RESTORE_COMMITTED=0
    : > "$MZD_REPORT/changed"
    mzd_system_lock /tmp/mzd-restore-originals.lock || exit 1
    mzd_system_lock "$MZD_PACKAGE_LOCK" || exit 1
    mzd_system_lock "$LOCK" || exit 1
    mzd_recovery_validate && mzd_recovery_probe || exit 1
    [ "$RECOVERY_TOKEN" = "$1" ] || mzd_fail 'The file or tweak information changed after confirmation. Nothing restored; inspect it again.'
    required=$(du -sk "$APP" "$APP.org" | awk '{n+=$1} END {print n+16384}')
    available=$(df -Pk "$MZD_USB" | awk 'NR==2 {print $4}')
    case "$available:$required" in *[!0-9:]*|:*|*:) mzd_fail 'Cannot determine USB archive space.' ;; esac
    [ "$available" -ge "$required" ] || mzd_fail 'Not enough USB space to archive both files.'
    # Never replace an older archive if the CMU clock/PID repeats after reboot.
    mkdir "$MZD_REPORT/files" && mkdir "$MZD_REPORT/files/1" || mzd_fail 'This report folder already contains an archive. No internal file was restored.'
    folder="$MZD_REPORT/files/1"
    printf '%s\n' "$APP" > "$folder/target.path"
    printf '%s\n' "$RECOVERY_OBSERVED" > "$folder/before.hash"
    printf '%s\n' "$ORIGINAL" > "$folder/original.hash"
    # USB may be FAT; preserve bytes without requiring Unix metadata support.
    cp "$APP" "$folder/before.data" && cp "$APP.org" "$folder/original.data" || mzd_fail 'Cannot archive both files; nothing restored.'
    cmp -s "$APP" "$folder/before.data" && cmp -s "$APP.org" "$folder/original.data" &&
        [ "$(mzd_hash "$folder/before.data")" = "$RECOVERY_OBSERVED" ] &&
        [ "$(mzd_hash "$folder/original.data")" = "$ORIGINAL" ] || mzd_fail 'USB archive verification failed; nothing restored.'
    available=$(df -Pk "$RECOVERY_MOUNT" | awk 'NR==2 {print $4}')
    needed=$(du -sk "$APP" "$APP.org" | awk '{n+=$1} END {print n+1024}')
    case "$available:$needed" in *[!0-9:]*|:*|*:) mzd_fail 'Cannot determine internal temporary space.' ;; esac
    [ "$available" -ge "$needed" ] || mzd_fail 'Not enough internal space for a verified temporary file.'
    sync
    mzd_restore_before_matches "$folder" "$APP" && cmp -s "$APP.org" "$folder/original.data" || mzd_fail 'Files changed after archiving; nothing restored.'
    mzd_system_watchdog_disable || exit 1
    mzd_system_remount_rw "$RECOVERY_MOUNT" || exit 1
    printf '1\n' > "$MZD_REPORT/changed" || exit 1
    mzd_restore_write "$APP" "$folder/original.data" || mzd_fail 'Restore write failed; rolling back.'
    [ "$(mzd_hash "$APP")" = "$ORIGINAL" ] || mzd_fail 'Restored file verification failed; rolling back.'
    RESTORE_COMMITTED=1
    cmp -s "$APP" "$folder/original.data" || mzd_fatal 'Restored file changed before backup removal. Do NOT reboot.'
    cmp -s "$APP.org" "$folder/original.data" || mzd_fatal 'Original restored, but backup changed before removal. Do NOT reboot.'
    rm -f "$APP.org" && [ ! -e "$APP.org" ] && [ ! -L "$APP.org" ] || mzd_fail 'Original restored, but the .org backup could not be removed. Keep the USB report.'
    MZD_STATUS=$MZD_REPORT
)
mzd_recovery_main() (
    command=$1; id=$2
    for library in manifest report system patch packages restore export; do . "$ROOT/lib/$library.sh" || exit 1; done
    mzd_manifest_id "$id" || exit 1
    mzd_manifest_load "$ROOT/tweaks/$id/manifest.conf" || exit 1
    [ "$ID" = "$id" ] || exit 1
    mzd_require_tools awk md5sum cut cp cmp patch mktemp readlink || exit 1
    if [ "$command" = restore-check ]; then
        [ ! -e "$MZD_PACKAGE_LOCK" ] && [ ! -e "$LOCK" ] || { mzd_recovery_error 'Another operation is active.'; exit 1; }
        mzd_recovery_validate && mzd_recovery_probe || exit 1
        [ ! -e "$MZD_PACKAGE_LOCK" ] && [ ! -e "$LOCK" ] || exit 1
        printf 'available\t%s\t%s\n' "$RECOVERY_TOKEN" "$APP"
        exit 0
    fi
    confirmed=$3
    case "$confirmed" in ''|*[!0-9a-f]*) exit 1 ;; esac
    [ "${#confirmed}" = 32 ] || exit 1
    mzd_require_tools df du mv mount sync date || exit 1
    mzd_export_mount || exit 1
    original_usb_ro=0
    case ",$EXPORT_MODE," in *,ro,*) original_usb_ro=1 ;; esac
    # Also restore USB mode if report initialization or a caught signal fails.
    trap 'code=$?; trap - 0; if [ "$original_usb_ro" = 1 ]; then mount -o ro,remount "$EXPORT_MOUNT" || { printf "USB cleanup failed. Do NOT reboot.\n" >&2; code=2; }; fi; exit "$code"' 0
    trap 'exit 2' INT TERM
    MZD_ORIGIN_USB=$EXPORT_MOUNT; export MZD_ORIGIN_USB
    report=$(mzd_recovery_run "$confirmed"); code=$?
    if [ "$original_usb_ro" = 1 ]; then
        if mount -o ro,remount "$EXPORT_MOUNT"; then original_usb_ro=0
        else
            printf 'USB cleanup failed. Do NOT reboot.\n' >&2
            [ -z "$report" ] || printf 'exit_code=2\n' > "$report/status.txt" || :
            exit 2
        fi
    fi
    [ "$code" = 0 ] || exit "$code"
    printf 'Original file restored. ALL patches on this file were removed.\nYou can now retry Install.\nReports: %s\n' "$report"
)
