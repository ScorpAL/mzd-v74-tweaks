# Remove broken saved installations through the GUI

Date: 2026-10-30

## Behavior

A broken detail dialog keeps Retry status and can show an additional Uninstall
button. A detail-only read-only uninstall-check endpoint verifies the saved
snapshot inventory, ownership/settings, recorded state, uninstall contract and
dependents. Missing or changed snapshots and active package locks refuse the
offer with a reason. No worker is executed by this eligibility check.

Uninstall uses the existing controller and saved version, repeating mutation
checks. Success returns to an uninstalled state; installing the USB version
requires another explicit action. Stale responses cannot reveal the button in
another/closed view. Critical failures retain the existing global action lock.

## Validation

- test_packages.py: 60 real adapter checks passed. Added absent receipt,
  failed-but-valid snapshot, read-only eligibility/no worker execution, changed
  manifest, active lock and dependent-package refusal checks. The existing saved
  uninstall then removed the failed package.
- test-ui.cjs: all checks passed, including the new broken-saved-uninstall cases:
  explicit action only, saved version display, rotary/Enter access, no automatic
  reinstall, invalid responses, stale replies and critical uninstall failure.
- test-es5.cjs, test-transport.cjs and tools/validate.py (11 tweaks) passed.
- Error-level ShellCheck on installer.sh and git diff --check passed.
- The offline styling preview simulates a saved failed Shorter List Delay package
  so its Uninstall button can be inspected without touching a vehicle.

Limits: isolated host/DOM tests, no physical CMU removal in this run. The new
endpoint uses the existing POSIX shell/package checks; no new tool options or
installation/migration behavior were introduced.
