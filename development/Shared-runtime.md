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

restore.sh: internal backup discovery, USB archives, owned reset hooks, verified publication and rollback.

restart.sh: explicitly requested launcher reboot after successful cleanup; never called by workers.

transport.sh: factory Lua transport startup and liveness.
logging.sh: literal installer.conf parsing for normal/debug/off diagnostics.
lua-bridge/: loopback HTTP, direct process execution and wire encoding.

packages.sh: persistent per-tweak code/runtime snapshots, versioned receipts,
fast registered status, selective removal dispatch and cross-tweak path guards.
Each installed package owns its helper snapshot; new USB helpers are never
sourced by an old worker. See [Persistent packages](Persistent-packages.md).

settings.sh and settings.awk: literal typed schemas, normalized effective values,
saved configuration validation and `mzd_setting` for workers. They do not source
configuration or evaluate values. The GUI, shell and developer validator share
the contract in [Manifest format](Manifest-format.md#optional-tweak-settings).

shim.sh and shim-preload.awk: shared .so/LD_PRELOAD state inspection, verified
payload placement, multi-loader configuration edits, rollback and reset hooks.
No native shim is executed by these helpers and no service is restarted.

components.sh/components.awk: data-only component plans, derived ownership and
OEM catalogs. config-map.awk: configuration keys mapped to normalized manifest
settings, without duplicate defaults or evaluation.

bundle.sh: mixed payload/loader/patch transactions, saved-configuration removal,
rollback journal, reset hooks and read-only compatibility messages. See the
[component example](examples/bundle/README.md) for the supported scope and limits.

vehicle.sh: bounded read-only VBS control/HUD queries. It reports facts and
unknown values; feature-specific compatibility policy belongs to each worker.
