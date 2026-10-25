# Optional restart on Exit

Local UI and isolated shell evidence; physical CMU restart is not yet tested.

UI assertions cover successful install/uninstall requiring restart, explicit
Restart versus Exit without reboot, no changes, failed/critical operations,
non-rebooting services and a rejected restart request. Existing controller tests
exercise Back on the restart dialog as Exit without reboot.

The actual installer event adapter and extracted launcher finish function are
exercised with fake reboot/mount/sync commands. Tests verify request markers,
active-job refusal, normal Exit, logging/mount cleanup before reboot, suppression
on launcher/mount errors, and a reboot command returning failure. No actual reboot
or vehicle modification was performed.

Vehicle follow-up: make a reviewed restart-requiring change, verify both dialog
choices, ensure normal Mazda UI return on Exit and CMU restart on Restart.
