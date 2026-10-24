# No List Beep

Mute the two long multicontroller list beeps.

- Firmware: 74.00.324
- Target: `/jci/gui/common/controls/List2/js/List2Ctrl.js`
- Shared lock group: `List2Ctrl`
- Restart required for UI behavior: true

Run `sh tweaks/list-beep/run.sh status`, `install` or `uninstall` from the USB
repository layout. Status inspects the current file, not a cached flag. A complete
reversible patch is installed; a supported forward patch is uninstalled.
Unsupported content is unavailable; demonstrable partial changes are broken.

Modifying actions recheck prerequisites, use exact reversible patches, retain a
verified OEM backup, preserve other tweaks and restore owned mount/watchdog state.
See ../../../wiki/Worker-contract.md and ../../../tests/runs/ for protocol and evidence.
The shared runtime/contract migration still requires a fresh vehicle test.
