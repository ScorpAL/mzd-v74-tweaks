# Main Menu Loop

Wrap between the first and last main-menu icons.

- Firmware: 74.00.324
- Target: `/jci/gui/apps/system/controls/MainMenu/js/MainMenuCtrl.js`
- Shared lock group: `MainMenuCtrl`
- Restart required for UI behavior: true

Run `sh tweaks/main-menu-loop/run.sh status`, `install` or `uninstall` from the USB
repository layout. Public status reads the saved installation record; modifying actions perform a deep target check. A complete
reversible patch is installed; a supported forward patch is uninstalled.
Unsupported content is unavailable; demonstrable partial changes are broken.

Modifying actions recheck prerequisites, use exact reversible patches, retain a
verified OEM backup, preserve other tweaks and restore owned mount/watchdog state.
See ../Worker-contract.md and ../test-runs/ for protocol and evidence.
See the reviewed test records for the exact vehicle and isolated test scope.
