# Instrument Cluster / HUD Language: standalone test package

Scope: release 0.10.22's unmodified libpatch-svcjciblmsettings.so as one
independent launcher tweak, with its own manifest-generated libpatch.conf.
No AA Mod configuration/library is imported or modified.

## Provenance

Release ZIP SHA256 and the extracted library were checked before use. The source
snapshot at commit 187f331320e647063c85068b4975a83ecd87c64d and upstream AGPL license
are supplied with the tweak. OEM settings/client fingerprints were read from the
private 74.00.324 dump; OEM files themselves are not committed.
See [the tweak README](../../usb/tweaks/cluster-language/README.md).

## Isolated controller and UI

- 14 real-package checks passed: defaults, HUD warnings, refusal of an already
  referenced foreign copy, unsupported native module, correct service selection,
  missing-target/changed-payload deep states, read-only inspection, and saved
  uninstall after both USB assets and the native module changed.
- 30 shared-shim checks passed, including unrelated self-closing services and
  commented service definitions, rollback/reset and selective removal.
- Both complete OEM SM files accept an insertion followed by byte-exact removal.
- UI suite passed, including parsing the real tweak's settings/default and the
  generic compatibility/detail behavior. Manifest suite, ten-tweak validation,
  error-level ShellCheck and git diff --check passed.

## Original CMU tools in emulation

Focused run: ORIGINAL_SHIM_TOOLS_PASSED, ORIGINAL_COMPONENT_TOOLS_PASSED,
ORIGINAL_OEM_CLUSTER_LAYOUT_PASSED and LUA_TEST_RESULT=0.

The full worker test uses the original ARM BusyBox shell and applets, the real
release library as a copied asset, and private copies of the two OEM SM configs.
Only paths, mount/watchdog state and DBus replies are isolated fixtures. Native
module hash checks use synthetic files; no OEM service is launched. Mount/DBus
commands are mocked; the fixture's tmpfs is mounted by the appliance setup.
This exercises the worker directly; the persistent controller is exercised by
the separate isolated real-package test above.

Full worker run passed ORIGINAL_CLUSTER_WORKER_PASSED and LUA_TEST_RESULT=0:
Install, installed status, byte-verified payload/config, Uninstall, uninstalled
status, byte-exact restoration of both OEM SM configs, removed payload directory,
restored watchdog and released lock. The nested emulation took about 25 minutes;
this is not a measurement of vehicle installation speed.

The initial OEM-layout check exposed a parser defect: unrelated self-closing
service declarations were considered unterminated blocks. The parser now handles
those entries and ignores XML comments for structure/ownership inspection while
preserving all original bytes. Selected self-closing or ambiguous service blocks
remain a safe refusal.

## Test delivery and limits

The local USB ZIP was expanded for cross-testing: it contains the current runnable
launcher/runtime and all ten available tweaks/tools, with no temporary SSH entry
or collected reports/logs.
ZIP integrity and byte comparison against the current runtime files passed.

No physical CMU was accessed. The .so was never dlopened/preloaded in the tests;
these checks verify installer behavior and old-tool compatibility, not the
functional native hook or vehicle startup. Piotr must still verify actual
cluster/HUD text, street names and removal after reboot. HUD absence/type is a
warning, since the instrument-cluster override can still apply. Region/language
benefit is not guessed and does not block installation.
