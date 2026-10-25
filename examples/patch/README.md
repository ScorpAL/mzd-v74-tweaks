# Patch-worker template

This is the complete List Beep implementation as a concrete reference. To add a
new tweak, copy to usb/tweaks/<new-id>/, then change its manifest.conf and patch. ID, target, firmware, OEM backup
fingerprint, lock group and dependencies are declared only in the manifest.
Add relevant tests.
Do not install this unchanged example under a second ID: it changes List Beep.
The folder must live under usb/tweaks/ to resolve ../../lib/ at runtime. This example
is not automatically discovered. See CONTRIBUTING.md and wiki/Worker-contract.md.
