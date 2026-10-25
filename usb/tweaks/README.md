# Launcher tweaks

Each immediate child folder contains manifest.conf, run.sh, README.md and assets/.
The launcher discovers these folders directly; grouping is manifest data.

Shared helpers live in ../lib/. Keep the repository runtime layout intact on USB.
Status returns installed, uninstalled, unavailable or broken, with required
stderr reasons for the last two states. It uses RAM scratch space only.
Install/uninstall reports are created under reports/diffpatch/ at the USB root.

Read ../../CONTRIBUTING.md and ../../wiki/Worker-contract.md. These are the maintained
workers for the new launcher; no older entrypoint or patch compatibility is kept.
