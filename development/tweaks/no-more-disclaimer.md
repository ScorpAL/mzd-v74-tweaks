# No More Disclaimer

Automatically acknowledges the Mazda factory startup disclaimer on firmware
74.00.324. It does not remove the installer's own startup notice with OK / Exit.

The diff replaces only the Disclaimer context in
`/jci/gui/apps/system/js/systemApp.js`: NoCtrlTmplt, transparent background,
logo surfaces, and the immediate DisposeIntroVideo / Global.Yes /
NotifyDisclaimerEnd event sequence. The existing timer functions and unrelated
contexts remain untouched. No full replacement systemApp.js is shipped.

Ported from [Piotr Mocko's v74 implementation](https://github.com/piotrmocko/mzd-v74-tweaks/blob/8b329eb9ffc7ce322786b2ad9980d37b887f4adc/jci-mods/systemApp.js),
based on the original MZD-AIO approach. The old commented dialog block is not
copied into the new context; runtime behavior matches the active upstream block.

Use `sh run.sh status`, `install` or `uninstall` from this folder in the complete
USB layout. Settings are read only from manifest.conf. Other tweaks touching
systemApp.js must use the same systemApp lock group. Uninstall reverses this
diff and preserves unrelated modifications; it never restores the whole OEM
file over later changes. The shared library owns backup validation, write/rollback
verification, mount/watchdog cleanup and result reporting.

Restart the CMU manually after changing this JavaScript tweak. No dialogs or
reboot commands are executed by this worker. Status inspection is read-only.
Partial/unsupported states follow the shared four-state contract.

Contract, patch-behavior and full-OEM round-trip checks are separate from a
vehicle test. See [reviewed evidence](../test-runs/README.md) for the tested scope.
