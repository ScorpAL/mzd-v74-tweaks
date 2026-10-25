# Original CMU Lua runtime tests

Run `python tests/transport/test-in-vm.py` on the development PC, optionally with
`--probe` to print runtime versions and check basic process execution.
Use `--packages` for the shorter saved-package install/uninstall test with the
original CMU BusyBox shell, without the full HTTP/process suite.
Use `--transport` to run the HTTP/process suite without repeating that roundtrip.
The default runs both. A timeout is incomplete evidence, not a passed check.

This isolated Linux/QEMU appliance uses the owner's existing private CMU runtime
from sibling `mcu_backup_20261021_203342/03_root_system.tar.gz` and existing
`mzd-cmu-emulator/` assets. It exercises the actual checked-in Lua transport,
HTTP authorization, separate streams, exit/signal handling, status deadlines,
closed stdin, output limits, disconnected clients, installer calls and jobs.
No physical vehicle connection or device write is made.

Private runtime copies, VM images and raw logs remain in ignored `.test-cache/`.
Never commit those files. No Python or emulator is required on the CMU.
