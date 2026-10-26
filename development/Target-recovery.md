# Confirmed recovery of an unmanaged patch target

This is a separate single-file action, not adoption of an old installation.
An ordinary failed install only becomes a recovery candidate when the package
controller completed the worker target inspection and found a blocked state.
It emits `MZD_RECOVERY_CANDIDATE` on stdout; the UI consumes this line rather
than interpreting human error text. Other install errors do not start recovery.

The UI then calls `installer.sh restore-check <id>`. This is read-only: it uses
private RAM copies and produces no USB reports, locks, remounts or service changes.
An eligible result is one line:

```text
available<TAB>confirmation-fingerprint<TAB>absolute-target-path<LF>
```

Eligibility requires a plain patch without cleanup hooks or additional owned
paths, matching firmware, regular non-symlink internal files, and a `.org` matching
the manifest's OEM fingerprint. The patch must apply reversibly to the OEM copy.
A current file supporting normal installation is not a recovery candidate.
Tool errors fail closed. Services and installed applications need their own
reviewed removal procedures and are deliberately excluded.

Mount eligibility uses software roles, never block-device names. The deepest
actual mount for target and backup must be the same supported Linux filesystem
at `/`, `/jci`, Resources (`/tmp/mnt/resources` or `/mnt/resources`) or persistent
data (`/tmp/mnt/data_persist` or `/mnt/data_persist`). The installer source mount
is excluded even if it uses ext4. Unknown child mounts and RAM/network filesystems
cannot fall back to an allowed parent. Package-store paths remain excluded by
the ownership checks below. A new filesystem layout needs an explicit role-map
update; a different device name does not.

Every saved package is verified before checking registered paths. A receipt for
the same ID, a shared target/backup or an owned ancestor container blocks recovery.
Registered paths are resolved before comparison to catch aliases of the same file.
Unrelated intact packages remain untouched. Unverifiable records also block it.

After explicit confirmation, `installer.sh restore-original <id> <fingerprint>`
acquires the global Restore, package and target locks and rechecks eligibility.
The fingerprint binds the ID, version, firmware, target path, expected OEM hash
and observed file hash. Changing the target definition, backup expectation or
file contents since the offer requires a fresh confirmation.
Current and original files are archived and verified on the originating USB in
`reports/diffpatch/restore-file-<id>-.../files/1/`, with hashes and the target path.
Free space is checked before the internal filesystem is remounted writable.
Reports use atomically created unique folders so a reset CMU clock or repeated
process ID cannot reuse an earlier report's rollback state or overwrite archives.

The existing same-directory publication and rollback helpers restore the file.
Only after verification is the internal `.org` removed. Locks, watchdog and mount
state are cleaned up; USB mode is restored after report writing. Unknown concurrent
edits are not overwritten during rollback. Uncertain rollback/cleanup is critical
(exit 2). An ordinary failure after commit can leave the original restored and its
`.org` retained, for example when backup deletion fails; the report states this.

The GUI does not reinstall automatically. After successful Restore and OK, the
user may select Install again. Restore requests a restart recommendation on Exit.
Back or Escape on the confirmation makes no changes. No restart is automatic.

Run `python tests/contract/test_recovery.py` and `node tests/installer/test-ui.cjs`.
The offline preview demonstrates the offer when installing No More Disclaimer;
its restore and subsequent install are simulated. This proves no vehicle behavior.
