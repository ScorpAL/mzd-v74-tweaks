# Shared shim installer example

A shim is an ARM shared library (`.so`) loaded into an existing CMU process with
`LD_PRELOAD`. It can intercept native functions that JavaScript patches cannot
change. The installer does not implement that interception: a tweak author
supplies the library and verifies that it supports the relevant OEM modules.

This example exports one unused function. It has no constructor and overrides
no CMU symbol. Its purpose is to demonstrate loader registration, status,
rollback, saved uninstall and System Restore without a functional vehicle tweak.

## Prepare the example as a developer

Build the asset with the CMU ARM EABI soft-float toolchain:

```sh
sh development/examples/shim/build.sh /path/to/m3-toolchain
# Alternatively: CC=/path/to/arm-...-gcc sh development/examples/shim/build.sh
```

The source and build script are supplied; no compiled sample is included. An
ARM compiler was not available on the development host for this change. The
helper refuses a missing/unsupported asset. Never rename a host/x86 library to
`.so` and treat it as an ARM build. The example has no libc dependencies, but
real shims must be built against the CMU's compatible ABI/libraries.

Copy this complete folder as `usb/tweaks/shim-example/`, including the built
`assets/shim-example.so`. End users run the prepared package without a build step.
Firmware 74.00.324 and verified OEM loader backups are required. Installation
adds the inert library to jciMMUI in sm.conf and sm_WCP.conf; it does not restart
MMUI. Restart via the launcher when ready. No physical load/boot test is claimed.

## What another author changes

- Stable ID, name/description/version and applicable firmware.
- `shim_asset`, `shim_path` and `shim_service` in manifest.conf.
- The primary target/OEM fingerprint and any `shim_extra_targets` records.
- `shim_checks` with path:MD5 records for native modules that the real shim needs.
- The compiled library and its source/build provenance.

Keep the thin run.sh/reset.sh wrappers. Shared runtime owns the loader/payload
transaction. Ownership paths are derived from metadata: both loader configs,
the shim payload and its per-tweak directory. Do not duplicate these in a
managed-paths.tsv. Register additional custom files explicitly and use a reviewed
worker/reset hook if a future tweak performs more than this shim installation.

The installer preserves other preload tokens, never replaces a foreign `.so`,
and never sources a manifest. Saved uninstall uses the old matching worker,
helpers and library even if the USB has a newer version. System Restore archives
the payload, restores loader originals first and only then removes verified shim
files. Running processes keep their mapped code until restart.

The helper preserves foreign preload entries; it cannot decide whether two
libraries intercept the same functions compatibly. A functional tweak must
provide its own reviewed prerequisites and declare known requires/conflicts.
Do not treat an old unmanaged copy of the same functional shim as an independent
compatible tweak or silently adopt it.
