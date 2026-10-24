#!/bin/sh
# No List Beep for Mazda firmware 74.00.324.
# Launcher worker; shared runtime helpers are in ../../lib/.
#
# Reading guide:
#   1. Validate the requested action without changing the system.
#   2. Define local reporting, system-state and patch helpers.
#   3. Set this tweak's paths/checksum in the configuration section below.
#   4. Run the installation flow at the end of the file.
# The manifest describes the tweak for discovery; this script executes it.
set -u

# Help and invalid actions return before reports, mounts or system changes.
mzd_worker_usage() {
    echo 'Usage: sh run.sh <install|uninstall|status>'
    echo 'No arguments or --help: show usage without changing anything.'
}

if [ "$#" -gt 1 ]
then
    echo 'Expected exactly one action, or no arguments for usage.' >&2
    mzd_worker_usage >&2
    exit 1
fi
ACTION=${1:-}
case "$ACTION" in
    ''|--help|-h)
        mzd_worker_usage
        exit 0
        ;;
    install|uninstall|status)
        ;;
    *)
        echo 'Unknown action. Use install, uninstall or status.' >&2
        exit 1
        ;;
esac

# Run directly from the ready-to-use repository; no build step is needed.
SELF=$(readlink -f "$0") || exit 1
HERE=$(dirname "$SELF")

# The repository is the ready-to-run USB package. Verify shared helpers before
# sourcing them; checksums detect package corruption, not malicious changes.
ROOT=$(CDPATH= cd "$HERE/../.." && pwd) || exit 1
for library in report system patch status; do
    file="$ROOT/lib/$library.sh"
    expected=$(cut -c1-32 "$file.md5" 2>/dev/null)
    actual=$(md5sum "$file" 2>/dev/null | cut -d' ' -f1)
    if [ -z "$expected" ] || [ "$expected" != "$actual" ]; then
        printf 'ERROR: Shared library checksum mismatch: %s\n' "$library" >&2
        exit 1
    fi
    . "$file" || exit 1
done

# --- Tweak configuration --------------------------------------------------
# Maintain these values together with manifest.json; offline tests check them.
# ORIGINAL identifies the unmodified OEM file, not a file with other tweaks.
# Tweaks editing the same file share LOCK to avoid simultaneous writes.
# JSON is not executed or parsed on the CMU.
ID=list-beep
FIRMWARE=74.00.324
APP=/jci/gui/common/controls/List2/js/List2Ctrl.js
ORIGINAL=e111883b9dcbeb6bb154521826fcacac
LOCK=/tmp/mzd-List2Ctrl-tweak.lock
PATCH_FILE="$HERE/assets/change.patch"



# Declared dependencies/conflicts are enforced for direct CLI calls as well.
REQUIRES=''
CONFLICTS=''
if [ "$ACTION" = status ]; then
    mzd_read_status
    exit $?
fi
# Recheck immediately before opening a modifying session.
mzd_action_preflight || exit 1

# --- Execution flow -------------------------------------------------------
# Open USB reports and register cleanup before acquiring a lock. Cleanup restores
# only the mount/watchdog state changed by this invocation, including on failure.
mzd_begin "$SELF" "$ID" mzd_system_cleanup
mzd_system_begin
mzd_require_tools awk md5sum cp cmp || exit 1
mzd_require_assets "$SELF" "$HERE/manifest.json" || exit 1
mzd_validate_firmware "$FIRMWARE" || exit 1
mzd_system_lock "$LOCK" || exit 1

# Probe both patch directions on USB copies before making the target writable.
# Keep a complete pre-change copy so rollback preserves other installed tweaks.
CONTEXT="$MZD_REPORT/target"
mzd_patch_prepare "$APP" "$PATCH_FILE" "$ORIGINAL" "$CONTEXT" || exit 1
STATE=$(mzd_patch_state "$CONTEXT") || exit 1


# Repeated install/uninstall is a successful no-op for the patch itself.
NO_CHANGE=0
case "$ACTION:$STATE" in
    install:installed|uninstall:uninstalled) NO_CHANGE=1 ;;
esac
if [ "$NO_CHANGE" = 0 ]
then
    mzd_patch_validate_backup "$CONTEXT" || exit 1
fi

# Apply only this tweak's diff. Uninstall reverses that diff and keeps other
# modifications in the same target file; it does not restore the whole OEM file.
USB=$MZD_USB
REPORT=$MZD_REPORT
mzd_report_message "$ACTION in progress. Do not remove the USB drive."
: # No service-specific preparation.
if [ "$NO_CHANGE" = 0 ]
then
    mzd_system_watchdog_disable || exit 1
    mzd_system_remount_rw / || exit 1
    mzd_patch_apply "$CONTEXT" "$ACTION" || exit $?
fi
: # No service-specific completion.

# Report completion; the launcher owns dialogs and any reboot decision.
if [ "$NO_CHANGE" = 1 ]
then
    MZD_SUCCESS="Requested setting is already present.
Reports: $MZD_REPORT"
else
    MZD_SUCCESS="$ACTION completed. Other changes were preserved.
Reports: $MZD_REPORT"
fi
