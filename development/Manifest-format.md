# Manifest format

Each tweak has one `manifest.conf`. It supplies both launcher metadata and worker
settings. The shell uses `usb/lib/manifest.sh`; `installer.sh manifest ID` validates
and forwards the same text to the UI. No settings are copied into run.sh, generated
from another file or interpreted as shell code.

```ini
contract_version=1
id=list-beep
name=No List Beep
description=Mute the two long multicontroller list beeps.
version=0.8.0
type=patch
group=interface
firmware=74.00.324
entrypoint=run.sh
actions=install uninstall status
target=/jci/gui/common/controls/List2/js/List2Ctrl.js
oem_backup_md5=e111883b9dcbeb6bb154521826fcacac
lock_group=List2Ctrl
status_scope=target-patch
reboot_required=true
requires=
conflicts=
```

## Rules

- One field per line, split at the **first** `=`. Keys are lowercase as shown.
- Values are literal text. Use no wrapping quotes or shell escapes. Extra `=`,
  `#`, `$()`, backticks and quotes inside text values remain text, never commands.
- Empty lines, space-only lines and lines starting with `#` are ignored.
  No inline comments, multiline values, tabs or other control characters.
- LF and CRLF line endings and a missing final newline are supported.
- Unknown, duplicate or missing required fields fail with a clear error.
- Version and the currently supported single firmware use three numeric components.
- `actions` is `install uninstall status`, or `run status` for a command.
- `requires` and `conflicts` are space-separated IDs; an empty value means none.
- `reboot_required` is exactly `true` or `false`.
- Patch/service workers additionally require `target`, `oem_backup_md5` and
  `lock_group`. A shared lock is derived from the lock group.
- `oem_backup_md5` identifies the unmodified OEM backup. It is **not** a checksum
  requirement for a currently patched target. Other tweaks can edit that target.

Project scripts, manifests, libraries, assets and binaries have no `.md5`
sidecars. The patch engine still fingerprints vehicle backups and verifies writes
and rollback. Those checks protect vehicle state and are independent of sidecars.

Invalid manifest data is an inspection failure: exit 1, empty stdout, reason on
stderr. An unsupported firmware or incompatible target remains a successfully
determined `unavailable` state, as specified in the worker contract.

## Optional command progress

`progress=true` enables asynchronous Run execution for command workers. It defaults to false and must be a literal boolean. A command may use `target` for its source directory; OEM backup hashes and patch locks are not required for commands.

The launcher calls `installer.sh start-run <id>`, polls `job-status <token>`, and reads `job-output <token> stdout|stderr` after completion. Jobs and progress files live in the temporary installer session, not on USB. The Lua bridge executes these short requests serially.

## Reset and confirmation metadata

- `confirmation`: optional literal warning shown in a second confirmation dialog
  before a command runs. No shell evaluation. Cancelling executes no worker.
- `refresh_all`: optional boolean, default false; recheck all tweak statuses after
  acknowledging an operation result. Restore declares true because it affects
  multiple files/tweaks, even when a later cleanup phase fails.
- `reset_entrypoint`: optional fixed value `reset.sh`. Required by repository
  validation for service/files workers owning persistent extras. The reset hook
  must be a regular local file, not a link.
