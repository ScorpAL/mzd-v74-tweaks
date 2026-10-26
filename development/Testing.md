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

## Offline styling preview on Windows

Open `tools/preview.cmd` to rebuild and open a disposable local HTML preview.
It embeds current UI files and simulated tweak states. Actions are simulated;
it never executes a vehicle worker or restarts the computer. Rebuild after editing
CSS or JavaScript. Python, Node.js and a web server are not needed for this preview.
The PowerShell entrypoint also supports `tools/preview.ps1 -NoOpen`.

## Evidence

Keep isolated, emulated and physical CMU results distinct. Use the
[vehicle test guide](Vehicle-testing.md) and store sanitized records in
[test-runs/](test-runs/README.md). Raw logs, firmware and keys do not belong in Git.
