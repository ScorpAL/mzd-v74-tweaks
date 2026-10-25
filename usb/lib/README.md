# Shared runtime

manifest.sh: literal KEY=VALUE parsing and configuration validation.
report.sh: asset availability checks, firmware checks, reports and outcome severity.
system.sh: owned locks, writable mounts, watchdog and cleanup.
patch.sh: exact reversible patch probes, backups, writes and rollback.
status.sh: read-only state, prerequisites, dependencies and action preflight.

Workers source these trusted code libraries; manifest.conf is read as data.
There are no project-file checksum sidecars. A shared helper change
requires tests for every affected tweak. Do not move tweak-specific policy here.

export.sh: read-only source exports, originating USB detection, unique output folders and progress.
jobs.sh: detached command execution and RAM progress/result polling through the serial bridge.

metrics.sh: read-only CPU tick deltas and free space for mounted block filesystems.
