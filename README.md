# CMU Tweaks - development

Ready-to-run USB layout for the native shell bridge and styled Secondary Opera
launcher. This branch targets the new launcher directly. No MP3 entry,
compatibility layer or assembly step is included.

## Use

Download this branch, extract it, and copy the contents of `usb/` to the USB root, including
`jci-autoupdate` and the long `.up` filename. Insert the USB drive. The styled installer starts directly and shows a notice
with **OK** and **Exit**. Select OK to load the tweak menu. No Python, Node.js or compiler is required on the CMU.

Development files stay outside `usb/`; no assembly step is required.

The menu discovers `usb/tweaks/*/manifest.conf`, groups buttons by `group`, asks each
`run.sh status`, and calls its declared actions. Exit returns to the Mazda UI.
The header shows CPU utilization and free space percentages for mounted block
filesystems, refreshed every five seconds while idle. CPU utilization uses two
/proc/stat snapshots; telemetry pauses during scans and worker actions.

Only firmware **74.00.324** is currently supported by the included tweaks.

| Path | Purpose |
| --- | --- |
| `usb/autorun.sh`, `.up`, `usb/jci-autoupdate` | Automatic USB entry and process lifecycle |
| `usb/installer.sh` | Discovery and direct argument-based worker invocation |
| `usb/bin/` | Ready-to-run ARM shell bridge and HTTP adapter |
| `usb/ui/` | Styled launcher, compatible with the vehicle's Opera engine |
| `usb/tweaks/` | Nine maintained tweaks and System tools, assets, manifests and technical READMEs |
| `usb/lib/` | Shared worker helpers, USB exports and progress jobs |
| `docs/` | Website sources |
| `wiki/` | Sources published by the Wiki sync workflow |
| `examples/` | Hello command and patch-worker template |
| `src/` | Native ARM helper source; rebuilding is optional |
| `tests/contract/` | Manifest, worker interface and isolated behavior checks |
| `tests/installer/` | Functional UI and transport tests |
| `tests/runs/` | Reviewed evidence and manual vehicle test records |
| `tools/` | Development validation and optional native compilation |

## Restore originals

System includes an explicitly confirmed **Restore originals** command. It archives
current files and internal `.org` backups on USB, restores and verifies the files,
cleans up registered managed extras such as SSH, then removes internal `.org`
backups and rechecks all statuses. All patches on affected files are reset.
Unknown old backups cannot be authenticated as factory originals; unknown extra
files are not deleted. This is not a factory reset. See the
[restore worker](usb/tweaks/restore-originals/README.md).

## Offline styling preview (Windows)

Double-click `tools/preview.cmd` to open a disposable local HTML preview with
example states and simulated actions. It embeds the current UI and manifests;
no shell worker executes. Run it again after editing CSS or JavaScript to rebuild
the preview. Python, Node.js and a web server are not needed for this preview.
The tweak menu uses compact single-column rows with status on the right.

## State contract

`status` prints exactly one state and a newline on stdout, with exit code 0:
`installed`, `uninstalled`, `unavailable` or `broken`. The last two require an
explanation on stderr. A failed inspection leaves stdout empty and exits 1.
Status never creates USB reports, remounts storage or changes services.

Install/uninstall: 0 success, 1 ordinary failure, 2 critical/uncertain changes.
The launcher displays the result, then asks for status again. Workers never
open dialogs or reboot. Dependencies and conflicts are enforced by workers.

Read [CONTRIBUTING.md](CONTRIBUTING.md) and the [contract](wiki/Worker-contract.md)
before contributing. This is a reviewable development proposal, not an upstream
agreement or a released 2.0 version.

## Evidence

The preceding launcher displayed and operated in the vehicle. SSH installation,
password login on port 22 and uninstallation were also checked on the vehicle.
This shared-library layout and contract v1 are new and require their own vehicle
run; isolated CI checks are not a vehicle test. See `tests/runs/`.

Original repository: https://github.com/piotrmocko/mzd-v74-tweaks.
Existing authorship remains in Git history; migration is not a claim of ownership.
