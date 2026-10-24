# CMU Tweaks — development

Ready-to-run USB layout for the native shell bridge and styled Secondary Opera
launcher. This branch targets the new launcher directly. No MP3 entry,
compatibility layer or assembly step is included.

## Use

Download this branch, extract it, and copy its contents to the USB root, including
`jci-autoupdate` and the long `.up` filename. Insert the USB drive and select
**Start**. No Python, Node.js or compiler is required on the CMU.

The menu discovers `tweaks/*/manifest.json`, groups buttons by `group`, asks each
`run.sh status`, and calls its declared actions. Exit returns to the Mazda UI.
Only firmware **74.00.324** is currently supported by the included tweaks.

| Path | Purpose |
| --- | --- |
| `autorun.sh`, `.up`, `jci-autoupdate` | Automatic USB entry and process lifecycle |
| `installer.sh` | Discovery and direct argument-based worker invocation |
| `bin/` | Ready-to-run ARM shell bridge and HTTP adapter |
| `ui/` | Styled launcher, compatible with the vehicle's Opera engine |
| `tweaks/` | Five maintained tweaks, assets, manifests and technical READMEs |
| `lib/` | Shared report, system, patch and read-only status functions |
| `docs/` | Website sources |
| `wiki/` | Sources published by the Wiki sync workflow |
| `examples/` | Hello command and patch-worker template |
| `src/` | Native ARM helper source; rebuilding is optional |
| `tests/contract/` | Manifest, worker interface and isolated behavior checks |
| `tests/installer/` | Functional UI and transport tests |
| `tests/runs/` | Reviewed evidence and manual vehicle test records |
| `tools/` | Development validation and optional native compilation |

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
