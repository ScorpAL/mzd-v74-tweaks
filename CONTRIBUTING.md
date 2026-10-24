# Contributing

Target branch: `development`. The `usb/` directory contains the runnable USB package. Copy its contents to the USB root.
Keep changes scoped to a tweak or a separately explained infrastructure change.
Do not introduce a second legacy launcher or generated runtime tree.

1. Read [the worker contract](wiki/Worker-contract.md).
2. Copy `examples/patch/` or `examples/hello/` into `usb/tweaks/<id>/`.
3. Supply an English manifest, README, entrypoint, assets and checksum sidecars.
4. Declare firmware, dependencies, conflicts, lock group and reboot needs.
   Mirror dependencies/conflicts in `REQUIRES`/`CONFLICTS`; CI checks parity.
5. Implement and test any hardware or component checks. With the shared runtime,
   define `mzd_check_prerequisites()` and emit a reason on stderr before returning
   failure. The status helper maps unmet prerequisites to unavailable/broken.
6. Register fixture cases for the new tweak in `tests/contract/test_workers.py`.
   Include installed, uninstalled, unavailable, broken, inspection failure,
   dependency/conflict handling and preservation of unrelated edits where applicable.
7. Install developer-only dependencies with `python -m pip install -r tools/requirements.txt`.
   Run `python tools/validate.py` and `python tests/contract/test_workers.py`.
   Run `node tests/installer/test-ui.cjs` and the transport test for UI changes.
   CI additionally runs ShellCheck and tests on BusyBox in Linux.
8. Record real vehicle results under `tests/runs/` using its template. Include
   firmware, commit, actions, expected/actual results and limits. Never commit
   keys, raw dumps or personal logs.

Runtime shell is POSIX sh and must work with the CMU BusyBox; notably grep has
no `-x` and patch has no `--dry-run`. Checksums detect accidental corruption,
not malicious packages. Refresh intentionally changed `.md5` files with
`python tools/checksums.py --update`; review the diff before committing.

PR checks validate metadata and the contract, exercise sandboxed real entrypoints,
and test UI processing. A green check does not prove arbitrary shell code safe
or replace code review and a vehicle test. New behavior needs relevant tests,
not merely a manifest that advertises it. Configure `Validate tweaks / contract`
as a required check in repository branch protection if merges must be blocked.
