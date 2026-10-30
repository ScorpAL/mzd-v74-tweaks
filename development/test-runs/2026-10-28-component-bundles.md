# Variable component bundles and native configuration

Local development changes; no vehicle connection, deployment or GitHub push.

## Implemented scope

- One worker transaction for multiple shims/services, loader configs, payload
  files, generated key/value configuration and reversible patches.
- Typed manifest settings remain the only source of defaults and allowed values.
  Config maps assign native key names without duplicating values.
- Saved settings/assets/code reconstruct configuration for uninstall and reset.
- Read-only detail compatibility messages distinguish blocks from warnings.
  Install rechecks requirements; uninstall does not require current HUD support.
- Bounded read-only HUD/control queries live in vehicle.sh. Region/language
  readers still require verified vehicle-specific sources; none are guessed.

## Isolated results

- Component schema: 12 matching developer/runtime grammar and unknown mapped
  setting checks passed.
- Component bundles: 17 real controller/reset checks passed on synthetic files.
  Includes two different services, two loaders, generated libpatch.conf, a JS
  patch, saved uninstall after USB asset replacement, last-write rollback,
  critical rollback payload retention, unknown reset payload refusal and
  prepare/finish ordering.
- Existing persistent packages: 50 adapter checks passed.
- Existing worker contract: 215 entrypoint checks passed.
- Manifest readers: 29 checks passed.
- UI and transport suites passed, including detail-only compatibility requests,
  blocked Install, actionable warnings, stale replies and saved Uninstall.
- Runtime validation (nine shipping tweaks), error-level ShellCheck and
  git diff --check passed.

Fixtures contain synthetic ARM ELF headers only. They are copied and checked,
never loaded or executed. No new functional native tweak is advertised.

## Original CMU tools in emulation

The focused --shims run passed ORIGINAL_SHIM_TOOLS_PASSED,
ORIGINAL_COMPONENT_TOOLS_PASSED and LUA_TEST_RESULT=0. It exercises the component
schema, manifest settings/config-map generation, warning/block protocol and HUD
response parsing with the original ARM BusyBox shell/awk. DBus replies are
mocked; this does not establish actual hardware communication or HUD behavior.

The original awk required a literal tab as the -F argument; the new shell
queries use printf to supply it. A test-only mock originally used a hyphen in
a shell function name, which old ash rejects. The mock now uses an executable
file. Runtime code uses the existing dbus-send executable, not that mock.

## Limits

The example is source-only and inert. No compiled real shim, ABI compatibility,
physical startup, HUD change or rendering test is claimed. Configuration formats
other than literal key/value need a reviewed renderer. Foreign configuration is
not silently imported. The worker transaction does not change the controller's
existing uninstall-old/install-new version replacement policy into an atomic
whole-upgrade rollback; replacement preflight protects against known asset,
configuration and compatibility failures before old removal.
