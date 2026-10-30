# Generic tweak settings

Date: 2026-10-27. Local working tree based on development 5617bb3.
Isolated fixture and original-runtime emulation evidence; no physical CMU test.
No firmware, vehicle credentials or private logs are included.

## Behavior

Manifest-driven number, boolean and choice controls replace the visual-only
settings prototype. Install/Run send literal argument arrays through the existing
Lua bridge. The shell validates types, bounds/steps, fixed choices, defaults and
unknown/duplicate/control-bearing input before worker execution or staging.

Installed packages include normalized effective settings in the verified saved
snapshot. Deep status, uninstall and reset use the selected saved configuration
and helper, including when the USB changes or its tweak folder is removed.
Installed values are shown read-only; changing them requires Uninstall/Install.
Same-version Install refuses a different effective configuration. Background
commands retain their own RAM configuration through completion.

The example under development/examples/settings prints its effective values and
does not configure log rotation. Copy it into usb/tweaks/settings-example for a
physical test. The browser preview uses the real controls with simulated output.

## Validation

- test_settings.py: 42 checks passed: shell/Python schema agreement, defaults,
  bounds/step, booleans/choices, unknown/duplicate/injected/multiline values,
  pre-mutation refusal, background lifetime, report settings copies, same-version
  refusal, upgrade removal with old options, saved-schema detail response,
  reset hook phases, missing/modified settings and uninstall without USB code.
- test_manifest.py: 22 checks passed.
- test_packages.py: 50 existing adapter checks passed.
- test_workers.py: 215 existing worker checks passed.
- test_restore.py: 15 scenarios passed.
- test_exports.py: 14 scenarios passed.
- test-ui.cjs and test-transport.cjs passed, including generic settings controls,
  selected argument arrays, saved read-only values, discarded drafts and
  multicontroller access in the DOM fixture.
- Repository validation and ShellCheck severity=error passed.
- Original ARM Lua/POSIX/socket transport run: 67 checks passed, including the
  original CMU BusyBox settings schema/normalization exercise.
- Original ARM BusyBox package controller installed with limit=35 and removed
  with its saved configuration after USB helper replacement:
  ORIGINAL_SHELL_PACKAGES_PASSED, LUA_TEST_RESULT=0.
- Focused original-shell settings validation after the final silent-check change:
  valid values, invalid range/step/choice/boolean, duplicate/multiline input and
  missing saved values passed; ORIGINAL_SETTINGS_PASSED, LUA_TEST_RESULT=0.

The focused native test exposed a failure when a validation-only helper emitted
normalized output through nested shell redirection under set -e. Validation now
uses an explicitly silent check mode. Error text is routed by the shell and does
not require /dev/stderr. This final path passed on the original BusyBox shell.

## Limits

The emulator uses original ARM BusyBox/Lua and modules inside an isolated Linux
appliance with guest utilities and private synthetic paths; it is not the actual
CMU service stack. The DOM tests do not verify physical display rendering or
real multicontroller events. A vehicle test of the example and native UI remains
required. No actual logrotate settings or other system tweak parameters were
changed by these tests.
