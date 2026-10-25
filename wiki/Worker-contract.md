# Worker contract v1

## Discovery

A tweak is `usb/tweaks/<id>/manifest.conf` plus `run.sh`. The manifest has
`contract_version=1`; see [Manifest format](Manifest-format.md). It is data, never
shell code. The launcher starts `/bin/sh <path>/run.sh <action>` using separate
arguments and captures stdout, stderr, exitCode, signals and output truncation.
No worker depends on interactive stdin, dialogs, a reboot or a build step.

Patch/service actions: install, uninstall, status. Command actions: run, status.
No arguments, --help or -h prints usage and exits 0 without side effects.
Extra arguments or unsupported actions return 1 with stderr and empty stdout.

## Status

| Exact stdout, followed by newline | Meaning |
| --- | --- |
| installed | Complete persistent installation, as documented by the tweak |
| uninstalled | Absent and ready for its install action; for commands, ready to run |
| unavailable | Unsupported target/firmware, missing component, prerequisite or conflict |
| broken | Evidence of a partial installation or missing/altered installed payload |

All four are successful inspections (exit 0). unavailable and broken MUST explain
why on stderr. Other successful states normally leave stderr empty. The launcher
shows the reason and provides Retry status instead of install/uninstall/run for
blocked states. Broken is not an automatic repair permission.

An inspection failure (for example unreadable target, invalid manifest or missing assets, missing
probe tool or concurrent change) returns 1, empty stdout and a reason on stderr.
Unknown target content alone is unavailable; only evidence of an installation
justifies broken. Patch workers detect complete forward/reverse states on RAM
copies. Individually reversible hunks identify partial installations. Content
that cannot establish ownership is unavailable, not guessed absent.

Status does not acquire modification locks, remount storage, change the watchdog,
start/stop services, create USB reports or call sync. It may read assets and use
private /tmp scratch directories, removed on exit and catchable signals.
Installed SSH means a complete persistent hook/payload/marker, not a live login.

## Prerequisites, dependencies and conflicts

Supported firmware is explicit in the manifest and enforced by run.sh. A worker
may define mzd_check_prerequisites() for hardware/component checks; it returns
failure with a clear stderr reason. Shared status maps that to unavailable, or
broken if an installed tweak has lost a prerequisite.

requires/conflicts contain space-separated tweak IDs in manifest.conf. The
shared reader loads all configuration for run.sh; no duplicate declarations or
JSON parser are needed. Dependencies
must be installed. Conflicts must report uninstalled; every unresolved or blocked status
blocks the operation. Cycles are rejected. Recheck immediately before modifying
anything. The manifest never substitutes for runtime checks.

## Modifying actions

0: verified success; 1: ordinary failure/refusal with known safe state;
2: critical rollback/cleanup failure or uncertain changes. Output is readable
progress/result text. stderr explains failures. Critical errors explicitly say
not to reboot. Signals/transport loss are not successful outcomes.

The worker owns target locks, prerequisites, exact patch application, backups,
rollback, mount/watchdog restoration and reports. Tweaks touching the same target
share a lock. Unified patches must contain exactly one relative `target.data`
file; no absolute or additional target paths are accepted. Apply/reverse only this tweak and preserve unrelated edits. Verify
writes and rollback. Do not overwrite an unknown OEM backup or silently replace
unknown service files. No automatic reboot. The launcher serializes actions,
shows the result and rechecks status after acknowledgement.

Tests must exercise the declared entrypoint, not only a copied transform.
Contract compliance and feature correctness are separate review responsibilities.

## Export commands and progress

System export commands declare `actions=run status`. A ready command returns `uninstalled`; the launcher labels this Ready. It does not claim an installed state after exporting. Unavailable sources, firmware, tools or USB space return `unavailable` with a reason. Status never copies data or scans the entire source tree for its size.

With optional `progress=true`, Run executes as a background job. Shared export workers call `mzd_export_progress <done> <total> <message>`; zero total means a phase without a meaningful percentage. Progress is written atomically in RAM. Completion retains the worker exit code, stdout and stderr for the usual result dialog. Only one progress job runs per session; Exit is disabled while working. Launcher cleanup waits for an active export before restoring storage state. Direct shell `run` remains synchronous.

Exports write unique folders below the originating USB's `exports/<id>/`. Completed folders end in `-complete`; failed exports retain `.incomplete` and diagnostics. They do not alter source data, root mount mode, watchdog or log rotation settings.
