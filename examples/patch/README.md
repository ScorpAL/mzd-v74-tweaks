# Patch-worker template

This is the complete List Beep implementation as a concrete reference. To add a
new tweak, copy to usb/tweaks/<new-id>/, then change its manifest, ID, target, firmware,
OEM checksum, lock group and patch. Update dependency constants and add tests.
Do not install this unchanged example under a second ID: it changes List Beep.
The folder must live under usb/tweaks/ to resolve ../../lib/ at runtime. This example
is not automatically discovered. See CONTRIBUTING.md and wiki/Worker-contract.md.
