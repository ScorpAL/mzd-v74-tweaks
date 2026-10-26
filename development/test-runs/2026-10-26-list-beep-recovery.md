# Pre-persistence List Beep recovery reproduction

Date: 2026-10-26. Isolated adapter tests and original-runtime emulation only.
No vehicle access or modification; no raw OEM payload committed.

The historical patch at `4682605^` and current List Beep patch are identical.
The private 74.00.324 List2Ctrl OEM file has MD5
`e111883b9dcbeb6bb154521826fcacac`. Applying the historical patch using the
original ARM BusyBox produces `bb290d22840f82b1be14400ddb41f1b0`, with the
unaltered original saved as the adjacent `.org`. No persistent receipt exists.

`python tests/transport/test-in-vm.py --recovery` runs the original ARM BusyBox
shell plus its awk, patch, readlink, md5sum, cut, cmp and mktemp applets inside
the local Linux appliance. Other VM utilities and mounts are isolated fixtures.
Both recovery at `f88e9db` and the simplified working-tree recovery returned
`available` for the historical installation. `BASELINE_RECOVERY_EXIT=0`,
`ORIGINAL_SHELL_RECOVERY_PASSED`, `LUA_TEST_RESULT=0`.
This does not reproduce Piotr's missing button or prove a device-side timeout.
His actual backup path/hash, firmware, mount table, ownership records and
restore-check stderr are needed to identify the specific refusal.

The working-tree recovery no longer uses patch probes: a matching OEM backup,
changed current file and existing path/mount/ownership guards establish whether
explicit restoration is possible. Installation preflight is unchanged. The
separately confirmed restore still archives both files and verifies writes
before deleting the internal backup.

Validation:

- `python tests/contract/test_recovery.py`: 68 adapter checks passed, including
  unrecognized old content, a normally applicable newer patch, missing/broken
  patch assets/tool, OEM mismatch refusal, ownership, rollback and cleanup.
  Windows symlink/alias fixtures skipped because host creation was unavailable.
- `python tests/contract/test_recovery_mounts.py`: 45 checks passed.
- `python tools/validate.py`: 9 tweaks validated.
- ShellCheck at repository severity (`error`) passed for changed shell files.
- `git diff --check` passed.

Local VM runtime and timing are not representative of physical CMU performance.
The test directly invokes the controller; it does not exercise Opera rendering
or the Lua bridge's production 30-second read-only deadline.
