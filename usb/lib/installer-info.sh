#!/bin/sh
# JSON-lines responses keep individual errors isolated in a single bridge call.
mzd_info_json_string() {
    # The sentinel preserves whether the original stream ended in a newline.
    (cat "$1" && printf '\001') | LC_ALL=C awk '
      BEGIN {printf "\""; for (i=1;i<32;i++) control[sprintf("%c",i)]=sprintf("\\u%04x",i)}
      {if (NR>1) printf "\\n"; sub(/\001$/, "");
       for (i=1;i<=length($0);i++) {
         c=substr($0,i,1);
         if (c=="\\") printf "\\\\";
         else if (c=="\"") printf "\\\"";
         else if (c in control) printf "%s",control[c];
         else printf "%s",c;
       }}
      END {printf "\""}'
}
mzd_info_capture() {
    key=$1; shift
    mzd_installer_main "$@" > "$info_scratch/out" 2> "$info_scratch/err"; code=$?
    printf '{"key":"%s","exitCode":%s,"stdout":' "$key" "$code"
    mzd_info_json_string "$info_scratch/out" || return 1
    printf ',"stderr":'
    mzd_info_json_string "$info_scratch/err" || return 1
    printf '}\n'
}
mzd_installer_info() (
    mode=$1; shift
    mzd_installer_packages || exit 1
    info_scratch=$(mktemp -d /tmp/mzd-info.XXXXXX) || exit 1
    info_locked=false
    trap 'if [ "$info_locked" = true ]; then rmdir "$MZD_PACKAGE_LOCK"; fi; [ -z "${MZD_PACKAGE_CACHE:-}" ] || rm -rf "$MZD_PACKAGE_CACHE"; rm -rf "$info_scratch"' 0
    trap 'exit 1' INT TERM
    if [ "$mode" = manifests ]; then
        [ "$#" = 0 ] || fail 'Manifest discovery takes no arguments.'
        mzd_installer_main list > "$info_scratch/ids" || exit 1
        while IFS= read -r info_id; do
            valid_id "$info_id" || exit 1
            mzd_info_capture "$info_id" manifest "$info_id" || exit 1
        done < "$info_scratch/ids"
    else
        [ "$#" = 2 ] && mzd_manifest_id "$1" || fail 'Expected tweak ID and detail sections.'
        info_id=$1; sections=$2
        set -f; set -- $sections
        [ "$#" -gt 0 ] && [ "$#" -le 6 ] || fail 'Invalid detail section count.'
        seen=' '
        for section do
            case "$section" in package-info|settings-info|update-info|preflight-info|uninstall-check|restore-check) ;; *) fail 'Unsupported detail section.' ;; esac
            case "$seen" in *" $section "*) fail 'Duplicate detail section.' ;; esac
            seen="$seen$section "
        done
        # Reuse verification only while holding the same mutation lock as actions.
        # Worker/recovery probes run after releasing it, with no cached checks.
        mkdir "$MZD_PACKAGE_LOCK" || fail 'Another package operation is active.'
        info_locked=true
        mzd_package_cache_begin || exit 1
        for section do
            case "$section" in package-info|settings-info|update-info)
                mzd_info_capture "$section" "$section" "$info_id" || exit 1 ;;
            esac
        done
        mzd_package_cache_clear || exit 1
        rm -rf "$MZD_PACKAGE_CACHE"; MZD_PACKAGE_CACHE=
        rmdir "$MZD_PACKAGE_LOCK" || exit 1
        info_locked=false
        for section do
            case "$section" in preflight-info|uninstall-check|restore-check)
                mzd_info_capture "$section" "$section" "$info_id" || exit 1 ;;
            esac
        done
    fi
)
