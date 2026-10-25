#!/bin/sh
# KEY=VALUE data only: no source, eval, expansion, quotes or inline comments.
mzd_manifest_error() { printf 'Manifest: %s\n' "$*" >&2; return 1; }
mzd_manifest_id() {
    case "$1" in ''|*[!a-z0-9-]*|-*|*-|*--*) return 1 ;; esac
}
mzd_manifest_load() {
    mzd_manifest_file=$1
    [ -f "$mzd_manifest_file" ] && [ ! -L "$mzd_manifest_file" ] || {
        mzd_manifest_error 'Missing manifest or symbolic link.'; return 1;
    }
    LC_ALL=C awk '{sub(/\r$/, ""); if ($0 ~ /[[:cntrl:]]/) bad=1} END {exit bad}' "$mzd_manifest_file" || {
        mzd_manifest_error 'Control characters are not allowed.'; return 1;
    }
    CONTRACT_VERSION=; ID=; NAME=; DESCRIPTION=; VERSION=; TYPE=; GROUP=
    FIRMWARE=; ENTRYPOINT=; ACTIONS=; APP=; ORIGINAL=; LOCK_GROUP=
    STATUS_SCOPE=; REBOOT_REQUIRED=; REQUIRES=; CONFLICTS=
    mzd_manifest_seen=' '; mzd_manifest_cr=$(printf '\r')
    while IFS= read -r mzd_manifest_line || [ -n "$mzd_manifest_line" ]; do
        mzd_manifest_line=${mzd_manifest_line%"$mzd_manifest_cr"}
        case "$mzd_manifest_line" in ''|'#'*) continue ;; esac
        case "$mzd_manifest_line" in *[![:space:]]*) ;; *) continue ;; esac
        case "$mzd_manifest_line" in *=*) ;; *) mzd_manifest_error 'Expected KEY=VALUE.'; return 1 ;; esac
        mzd_manifest_key=${mzd_manifest_line%%=*}
        mzd_manifest_value=${mzd_manifest_line#*=}
        case "$mzd_manifest_key" in
            contract_version|id|name|description|version|type|group|firmware|entrypoint|actions|target|oem_backup_md5|lock_group|status_scope|reboot_required|requires|conflicts) ;;
            *) mzd_manifest_error "Unknown field: $mzd_manifest_key"; return 1 ;;
        esac
        case "$mzd_manifest_seen" in *" $mzd_manifest_key "*) mzd_manifest_error "Duplicate field: $mzd_manifest_key"; return 1 ;; esac
        mzd_manifest_seen="$mzd_manifest_seen$mzd_manifest_key "
        case "$mzd_manifest_key" in
            contract_version) CONTRACT_VERSION=$mzd_manifest_value ;;
            id) ID=$mzd_manifest_value ;;
            name) NAME=$mzd_manifest_value ;;
            description) DESCRIPTION=$mzd_manifest_value ;;
            version) VERSION=$mzd_manifest_value ;;
            type) TYPE=$mzd_manifest_value ;;
            group) GROUP=$mzd_manifest_value ;;
            firmware) FIRMWARE=$mzd_manifest_value ;;
            entrypoint) ENTRYPOINT=$mzd_manifest_value ;;
            actions) ACTIONS=$mzd_manifest_value ;;
            target) APP=$mzd_manifest_value ;;
            oem_backup_md5) ORIGINAL=$mzd_manifest_value ;;
            lock_group) LOCK_GROUP=$mzd_manifest_value ;;
            status_scope) STATUS_SCOPE=$mzd_manifest_value ;;
            reboot_required) REBOOT_REQUIRED=$mzd_manifest_value ;;
            requires) REQUIRES=$mzd_manifest_value ;;
            conflicts) CONFLICTS=$mzd_manifest_value ;;
        esac
    done < "$mzd_manifest_file"
    for mzd_manifest_key in contract_version id name description version type group firmware entrypoint actions status_scope reboot_required requires conflicts; do
        case "$mzd_manifest_seen" in *" $mzd_manifest_key "*) ;; *) mzd_manifest_error "Missing field: $mzd_manifest_key"; return 1 ;; esac
    done
    [ "$CONTRACT_VERSION" = 1 ] && [ "$ENTRYPOINT" = run.sh ] || { mzd_manifest_error 'Unsupported contract or entrypoint.'; return 1; }
    mzd_manifest_id "$ID" && mzd_manifest_id "$GROUP" || { mzd_manifest_error 'Invalid ID or group.'; return 1; }
    [ -n "$NAME" ] && [ -n "$DESCRIPTION" ] || { mzd_manifest_error 'Name and description are required.'; return 1; }
    printf '%s\n' "$VERSION" "$FIRMWARE" | awk '!/^[0-9]+\.[0-9]+\.[0-9]+$/ {bad=1} END {exit bad}' || {
        mzd_manifest_error 'Version and firmware must have three numeric components.'; return 1;
    }
    case "$TYPE:$ACTIONS" in
        'command:run status') ;;
        'patch:install uninstall status'|'service:install uninstall status'|'files:install uninstall status') ;;
        *) mzd_manifest_error 'Type/actions do not match.'; return 1 ;;
    esac
    case "$STATUS_SCOPE" in target-patch|configuration|payload|service-health) ;; *) mzd_manifest_error 'Invalid status scope.'; return 1 ;; esac
    case "$REBOOT_REQUIRED" in true|false) ;; *) mzd_manifest_error 'Expected true or false for reboot_required.'; return 1 ;; esac
    printf '%s\n' "$REQUIRES" "$CONFLICTS" | awk '!/^[a-z0-9 -]*$/ {bad=1} END {exit bad}' || {
        mzd_manifest_error 'Invalid dependency list.'; return 1;
    }
    for mzd_manifest_dependency in $REQUIRES $CONFLICTS; do
        mzd_manifest_id "$mzd_manifest_dependency" || { mzd_manifest_error 'Invalid dependency ID.'; return 1; }
    done
    for mzd_manifest_list in "$REQUIRES" "$CONFLICTS"; do
        mzd_manifest_list_seen=' '
        for mzd_manifest_dependency in $mzd_manifest_list; do
            case "$mzd_manifest_list_seen" in *" $mzd_manifest_dependency "*) mzd_manifest_error 'Duplicate dependency ID.'; return 1 ;; esac
            mzd_manifest_list_seen="$mzd_manifest_list_seen$mzd_manifest_dependency "
        done
    done
    LOCK=
    if [ "$TYPE" != command ]; then
        case "$APP" in /*) ;; *) mzd_manifest_error 'An absolute target is required.'; return 1 ;; esac
        case "$ORIGINAL" in ''|*[!0-9a-f]*) mzd_manifest_error 'Invalid OEM backup checksum.'; return 1 ;; esac
        [ "${#ORIGINAL}" = 32 ] || { mzd_manifest_error 'Expected a 32-character OEM backup checksum.'; return 1; }
        case "$LOCK_GROUP" in ''|*[!A-Za-z0-9_-]*) mzd_manifest_error 'Invalid lock group.'; return 1 ;; esac
        LOCK="/tmp/mzd-$LOCK_GROUP-tweak.lock"
    fi
}
