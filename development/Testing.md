# Testing and styling preview

Run commands from the repository root. See [Contributing](CONTRIBUTING.md) for
required coverage. Checks use synthetic fixtures unless explicitly stated.

```sh
python tools/validate.py
python tests/contract/test_manifest.py
python tests/contract/test_workers.py
python tests/contract/test_packages.py
python tests/contract/test_report_messages.py
node tests/installer/test-ui.cjs
node tests/installer/test-transport.cjs
```

The [validation workflow](../.github/workflows/validate-tweaks.yml) lists the full
set, including BusyBox workers, patch combinations, SSH supervision, exports,
Restore, restart, metrics, logging, Lua syntax and disclaimer behavior. Run checks
appropriate to the change; a green check does not replace review or vehicle tests.

## Tests in CI

The [validation workflow](../.github/workflows/validate-tweaks.yml) runs four jobs:

| Job | Runner | What it checks |
| --- | --- | --- |
| `contract` | Ubuntu | manifests, `shellcheck`, Lua syntax and the contract tests, on the runner's own tools (dash, GNU) |
| `busybox` | ARM | builds the CMU-like BusyBox 1.19.2 and checks it against the CMU's BusyBox; only when its files change, otherwise it comes from the cache |
| `workers` | ARM | `tests/contract/test_workers.py` in an image that holds only that BusyBox, as user 0 (`cmu`) with the CMU's 128 kB stack |
| `launcher` | Ubuntu | the launcher UI tests (Node) |

If `workers` fails on a command that works on your PC, the CMU most likely lacks it or answers differently; see
[CMU BusyBox](CMU-BusyBox.md). The BusyBox, its checks and the image are described in
[tools/busybox/README.md](../tools/busybox/README.md).

## Worker tests on the CMU-like BusyBox

`python tests/contract/test_workers.py` above runs the worker scripts with your PC's shell and tools: quick, but
not what the CMU runs. In CI the same test runs in a Docker image that holds only the CMU-like BusyBox: it is
`/bin/sh` and every command, linked at the paths the CMU has, so a tweak meets the CMU's shell and options. The
image also has the CMU's users (user 0 is called `cmu`) and a Python for the test driver outside the scripts'
`PATH`. To run it the same way:

```sh
sh tools/busybox/build.sh
sh tools/busybox/image/make-image.sh .cache/cmu-busybox/busybox cmu-tweak-test:local
docker run --rm --network none --read-only --security-opt no-new-privileges --user 0:0 \
  --ulimit stack=131072:131072 --tmpfs /tmp:rw,exec,nosuid,size=128m \
  -e PATH=/sbin:/usr/sbin:/bin:/usr/bin -e HOME=/tmp -e CMU_TEST_BUSYBOX=1 \
  -v "$PWD:/repo:ro" -w /repo cmu-tweak-test:local /usr/local/bin/python3 tests/contract/test_workers.py
```

On an ARM machine that runs 32-bit ARM programs this is fast. On an x86 PC or an Apple Silicon Mac the ARM BusyBox
runs through qemu (`qemu-user-static`, included in Docker Desktop): it works, but the build takes a few minutes and
the test about ten. If Docker on your machine cannot start ARM programs in containers, see `QEMU_STATIC` in
[tools/busybox/README.md](../tools/busybox/README.md). `-e CMU_TEST_ONLY=<tweak-id>` limits the test to one tweak.

Rules for worker fixtures:

- With `CMU_TEST_BUSYBOX=1` every dedicated worker fixture links the BusyBox found on `PATH` into its private command
  directory; the cluster-language fixture follows the same setup as the shared patch workers.
- Keep mock mount, watchdog and service commands separate; never replace those guards.
- A fake command that hands over to the real one must call it at the path the CMU has: `/bin/mv`, `/bin/rm`,
  `/bin/cp`, `/bin/grep`, `/bin/cat` (not `/usr/bin/...`, which exists only on a PC). The image has nothing else.
- Commands the CMU has outside BusyBox (`dbus-send`, `lua`, `zip`, `unzip`, `ip`, the JCI programs) are not in the
  image: a test that needs one fakes it.

## Offline styling preview on Windows

Open `tools/preview.cmd` to rebuild and open a disposable local HTML preview.
It embeds current UI files and simulated tweak states. Actions are simulated;
it never executes a vehicle worker or restarts the computer. Rebuild after editing
CSS or JavaScript. Python, Node.js and a web server are not needed for this preview.
The PowerShell entrypoint also supports `tools/preview.ps1 -NoOpen`.
Use `tools/preview.ps1 -Settings` to open the real generic settings controls
with the non-destructive Settings Example manifest. The desktop bridge simulates
execution; use the runnable example on the CMU to test the actual shell handoff.
Use `tools/preview.ps1 -Restore` for an eligible Restore, or `-RestoreDenied`
for a simulated MD5 refusal. These shortcuts execute no real worker or restore.

Settings checks: `python tests/contract/test_settings.py` exercises schema
agreement, literal arguments, defaults/limits, background configuration lifetime,
saved snapshots and matching uninstall. The UI suite includes the real controls,
read-only installed values, draft cancellation and multicontroller access.
Use `python tests/transport/test-in-vm.py --settings` for focused native checks,
or `--packages` for a saved-settings install/uninstall roundtrip.
`python tests/transport/test-in-vm.py --transport` additionally runs the shared
settings reader with the original ARM CMU BusyBox shell/awk and existing Lua
transport. Keep emulation and physical-vehicle evidence separate.

## Evidence

Keep isolated, emulated and physical CMU results distinct. Use the
[vehicle test guide](Vehicle-testing.md) and store sanitized records in
[test-runs/](test-runs/README.md). Raw logs, firmware and keys do not belong in Git.

## Shared shim checks

`python tests/contract/test_shims.py` uses synthetic loader files and header-only
library fixtures. It exercises two shims sharing a service, selective removal,
saved assets, failed-second-write rollback, ownership, reset hooks and metadata
catalogs. It never loads or executes a fixture `.so`.

`python tests/transport/test-in-vm.py --shims` additionally checks the literal
manifest, ELF header guard and preload transformations with the original ARM
BusyBox shell/awk/dd/od. Neither test proves that a functional shim can load,
intercept symbols or boot on a physical CMU. The source-only inert example has
its own developer build step; runtime packages ship a prepared `.so` asset.

## Mixed component bundles

Run `python tests/contract/test_components.py` for matching developer/runtime
component grammar and configuration mappings, and
`python tests/contract/test_bundles.py` for the real controller with synthetic
payloads/targets. The latter includes distinct services, generated configuration,
a JS patch, later-write rollback, critical rollback payload retention, saved
uninstall and reset ownership checks. Header fixtures are never loaded.
The UI suite covers detail-only compatibility queries, blocks, warnings, info
messages and stale replies. The focused `--shims` emulation test additionally exercises the
component/config-map parsers and vehicle helper with original CMU shell/awk.

## Opera startup compatibility

Run `node tests/installer/test-es5.cjs` before the UI suite. It checks the runtime
scripts/inline bootstrap as ES5 and rejects function declarations in statement
blocks. Modern Node/Acorn accept some block-function extensions which the CMU
Opera strict parser can reject before the first readiness event. Node 22's
bundled Acorn parser supplies grammar parsing; no runtime npm dependency ships.
`node tests/installer/test-startup-errors.cjs` checks independent early parse/error
reporting through the transport iframe. Those diagnostics use event ui-error,
never ready, and are retained in normal USB ui.log on launcher cleanup.

Installer replug focus checks: `python tests/contract/test_session.py` exercises
the real RAM session helper and event adapter with private fixtures.
`node tests/installer/test-ui.cjs` verifies the browser handshake, no focus
requests while idle, and deferral during modifying actions. A CMU test must also
verify actual display/input restoration on replug and a fresh start after Exit.
The replug case must include a changed USB mount (for example sda1 to sdb1).
The firmware USB invocation must return while the detached installer stays alive.
Original-CMU Lua transport checks cover resolving the current installer path and
serving the cached transport page after its USB source disappears.
