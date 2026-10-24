# Shared runtime

report.sh: asset checks, firmware checks, reports and outcome severity.
system.sh: owned locks, writable mounts, watchdog and cleanup.
patch.sh: exact reversible patch probes, backups, writes and rollback.
status.sh: read-only state, prerequisites, dependencies and action preflight.

Workers verify .md5 sidecars before sourcing these files. A shared helper change
requires tests for every affected tweak. Do not move tweak-specific policy here.
