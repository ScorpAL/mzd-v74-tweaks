# Blocked status diagnostics

Date: 2026-10-30

## Problem and change

The batch status endpoint correctly exits zero for a completed inspection even
when a package is broken. Its reasons are in stdout rows, so the transport's
existing failed-command/stderr logger missed them. Normal transport logs now
include ID, blocked state and a bounded, escaped reason per affected row.
Refused-action diagnostics also include their request label. Missing saved
files and registered targets name the affected path.

Status remains read-only. The launcher saves its RAM transport log to USB on
Exit when USB logging is enabled. A failed receipt remains blocked; Retry
status does not execute the updated USB installer or silently discard it.
This change does not infer the root cause of an earlier SSH startup failure.

## Isolated host evidence

- tools/validate.py: 11 tweaks passed.
- tests/contract/test_packages.py: 52 checks passed, including failed-state
  batch reasons and the exact missing saved file path.
- Error-level ShellCheck on packages.sh and git diff --check passed.

## Original runtime evidence in emulation

- tests/transport/test-in-vm.py --transport: 67 checks passed.
- Original ARM CMU Lua 5.1, POSIX 5.1.19 and LuaSocket 2.0.2 under QEMU;
  original BusyBox settings/worker probes included.
- A synthetic failed receipt returned exit zero with a broken row and the
  failed-state reason; the actual server retained both in normal logging.
- Healthy rows stayed out of diagnostics. Process/HTTP/job handling and
  normal/debug/off helper lifecycle passed.
- No physical CMU, real SSH listener or vehicle installation was tested.

## Follow-up: preserve the failed operation, not just its state

The controller now captures modifying worker stdout/stderr and retains a bounded
failure.log beside state.conf with phase, exit code and saved worker path/version.
Failed post-action verification also records expected/actual status. Status reads
this record without writes. Old receipts without original details say so explicitly.
SSH Access 0.8.5 forwards startup phases and sshd runtime errors through the action
report's ssh-start.log into controller diagnostics before rollback.

Validation:

- test_packages.py: 55 actual adapter checks passed, including a concrete forced
  install error surviving later batch status and failed post-install verification.
- test_workers.py with CMU_TEST_ONLY=ssh: 46 entrypoint checks passed.
- test_ssh_service.py: passed, including a simulated sshd host-key error reaching
  supervisor stderr, plus normal Wi-Fi, startup, stop and rollback behavior.
- test_restore.py: 15 scenarios passed with the new diagnostic files allowed by
  package validation.
- test_logging.py passed with debug as the development default.
- Original ARM BusyBox shell/awk in the isolated --packages VM: saved
  install/uninstall passed, then a forced failure's phase, exit code and actual
  configuration-refusal message survived the subsequent broken status query.
  ORIGINAL_FAILURE_DIAGNOSTICS_PASSED; ORIGINAL_SHELL_PACKAGES_PASSED; result 0.
- A focused host check verified the subsequently added saved-version field and
  preservation of the worker error and return code.
- Error-level ShellCheck for the changed runtime shell and native fixture,
  manifest validation (11 tweaks) and git diff --check passed.

The real vehicle SSH failure has not been reproduced. This adds diagnostics;
it does not silently clear failed receipts or change the readiness timeout.
