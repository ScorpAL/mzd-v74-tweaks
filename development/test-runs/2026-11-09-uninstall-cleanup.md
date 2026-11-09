# Complete uninstall on a physical test CMU

- Date: 2026-11-09
- Runtime baseline: f972b0f, plus the empty-container cleanup correction in this change.
- Type: physical bench CMU, firmware 74.00.324 EU; operations through SSH.
- USB installer updated from this branch. SSH and the existing TP-Link driver remained installed.

| Check | Result |
| --- | --- |
| Remove the previously installed GUI consumers using their saved workers | Passed; old helper removed and SSH startup preserved. |
| Install List Beep and List Loop, then remove them individually | Passed; first removal retains the shared backup and remaining patch. Last removal restores content, modification time, mode, UID and GID, and removes `.org`. |
| Tetris update from 0.5.1 to temporary USB version 0.5.2 | Passed; mutable test data survives. USB version restored to 0.5.1 afterward. |
| Tetris uninstall with config preservation, then reinstall | Passed; saved data survives without being overwritten. |
| Full Tetris uninstall while Wallpaper Manager remains installed | Passed; Tetris data removed, shared runtime retained. |
| Remove Wallpaper Manager as the final GUI consumer | Passed; config, module, runtime, registry, provider and developer hook removed; SSH startup content unchanged. |
| Remove Safety Warnings install/uninstall | Passed; all 47 files restored with exact content, modification time, mode, UID and GID. No owned `.org` files or package receipt remain. |
| Repeat Tetris install/uninstall with SSH still installed | Passed after correcting empty-container pruning; unused data, gui-data and config-owners directories are absent. |

| Reboot after cleanup | Passed; SSH returned, only SSH and TP-Link receipts remain, GUI resources/data stay absent, root is read-only and watchdog is enabled. |

## Findings and limits

- Empty framework data directories initially remained until every package, including SSH, was removed. Cleanup now attempts safe `rmdir` after each removal; occupied directories remain untouched. The SSH/GUI coexistence fixture and the physical rerun passed.
- Existing legacy Safety and Common.js backups were byte-identical to their current targets. They were archived separately and removed as explicit test preparation; automatic migration of old installations is not claimed. Archived legacy GUI test data was also cleared before the fresh lifecycle checks.
- All inspected action reports completed with exit code zero. FAT USB report copies emit ownership-preservation warnings; target files and immutable persistent originals retain the verified metadata.
- Remaining `.org` files belong to the installed SSH and TP-Link driver. Neither package was removed or updated during this test.
- This run checks installer lifecycle and filesystem/service cleanup, not visual application behavior or vehicle signals. No injected storage or power failures were tested on hardware.
- Raw reports, recovery archives, keys and device-specific logs remain private or on USB.
