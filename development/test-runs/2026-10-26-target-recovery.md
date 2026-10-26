# Targeted original-file recovery

Date: 2026-10-26. Isolated fixtures on Windows; firmware contract 74.00.324.
No physical CMU, USB drive, services or real mounts were modified.

The final real-adapter recovery run passed 64 checks: verified OEM backup,
unmanaged installed/unknown content, read-only inspection, confirmation fingerprint,
FAT-compatible archive copies, retargeted/changed-version/changed-backup
confirmation refusal, unsupported firmware, USB/RAM target refusal,
missing/mismatched originals, patch-tool failures, active locks and stale targets.
Valid saved packages sharing a target or owning its parent container block the
action. Corrupt records also block it. Unrelated records remain byte-identical.

Failure scenarios cover no USB space, archive failure, write failure, unknown
concurrent writes, late changes to the restored target or original backup,
backup deletion failure and USB cleanup failure. Unknown edits remain untouched;
uncertain rollback/cleanup returns critical severity. Success archives both
inputs, restores the target, removes its .org and restores watchdog/mount state.
The matching-OEM symlink and managed path-alias fixtures cannot run on this Windows host because creating
symlinks is not permitted; it is included for the Linux CI run.

The existing global Restore suite passed all 15 isolated scenarios. UI tests
passed explicit confirmation, Back, controller cancellation, fingerprint passing,
malformed response rejection, no offer for unrelated failures, no automatic
installation and critical failure handling. Browser transport, report messages,
manifest/USB validation and ShellCheck error checks passed.

The package lifecycle suite passed all 50 checks and the real List Beep worker
passed 37 checks, including saved-package install/uninstall. The private reference
CMU dump identifies `/dev/ffx01p1` as the root relfs device; the final target
recovery fixtures exercise this device family as well as mmcblk mounts.

The repeated-clock/PID report fixture exposed reuse of stale system/rollback
state with the former timestamp/PID naming. Reports now use mktemp-created unique
directories. The regression verifies two restores with a fixed clock retain
separate archives and leave the earlier archived bytes unchanged.

Vehicle execution and the warning layout on the actual CMU are not yet verified.
The developer preview demonstrates the flow through No More Disclaimer using
simulated output only. The separate settings mockup remains local work.
