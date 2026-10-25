# SSH Access

Enable native SSH on port 22. Login: cmu / jci.

- Firmware: 74.00.324
- Target: `/jci/scripts/stage_wifi.sh`
- Shared lock group: `stage_wifi`
- Restart required for UI behavior: false

Run `sh tweaks/ssh/run.sh status`, `install` or `uninstall` from the USB
repository layout. Status inspects the current file, not a cached flag. A complete
reversible patch is installed; a supported forward patch is uninstalled.
Unsupported content is unavailable; demonstrable partial changes are broken.

SSH installed additionally requires matching service files and its enabled marker.
This persistent state does not assert a currently reachable port. Install starts
the owned service on port 22; login is cmu / jci. Uninstall removes its own hook,
payload, password overlay and firewall rule. An unrelated listener is not replaced.

Modifying actions recheck prerequisites, use exact reversible patches, retain a
verified OEM backup, preserve other tweaks and restore owned mount/watchdog state.
See ../../../wiki/Worker-contract.md and ../../../tests/runs/ for protocol and evidence.
The shared runtime/contract migration still requires a fresh vehicle test.

## System reset

`reset.sh check|prepare|finish` integrates with System > Restore originals. It
validates the remaining payload, archives it on USB, disables and stops the owned
supervisor, then deletes only its verified payload after the startup file has
been restored. Native SSH and unknown files are left alone. A missing or altered
payload with active runtime can require manual review. File rollback does not
automatically restart SSH. Never invoke finish alone; use the System reset tool.
