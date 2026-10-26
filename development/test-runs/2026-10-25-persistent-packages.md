# Persistent package controller â€” local verification

Date: 2026-10-25. Firmware contract: 74.00.324. Working tree based on b1f0624.
The owner explicitly requested local verification without pushing. The initial
implementation and isolated checks did not touch the vehicle. A later explicitly
authorized physical test is recorded below.

The package store is /tmp/mnt/data_persist/mzd-v74-tweaks/installed/<id>/.
The live SSH payload location under resources remains unchanged. All persistent
patch/service/files entrypoints route through the package controller, which
copies the worker, assets and helper snapshot before executing the installation.
There is no adoption of pre-receipt installations.

## Passed isolated checks

- 215 real worker entrypoint checks. Includes actual SSH and list-beep workers
  installing from saved snapshots, retaining USB reports and uninstalling after
  the USB service/patch payload was deliberately replaced with incompatible code.
- 46 adapter/package checks. Includes old versus new helpers, old uninstall from
  a newer USB, version replacement, pre-staging space refusal, absent USB tweak
  folders, immutable-file modification/missing files, interrupted/failed states,
  failed uninstall, required providers, owned files/directories, conflicting
  ownership, reset ordering, global locking and refusal of pre-receipt content.
- 15 real Restore scenarios. The added saved-package scenario uses the old reset
  hook despite incompatible replacement USB assets, archives/removes its receipt
  after verification and excludes an .org package asset from system restoration.
- Manifest parsing, 36 shared-target patch-order combinations, exports/jobs,
  restart lifecycle, diagnostics settings, read-only metrics and Hello checks.
- UI/browser-transport checks, including installed versus USB version display.
- ShellCheck error-level checks, shell syntax, manifest/USB layout validation and
  clean whitespace checks.

## Original CMU runtime in an isolated VM

The package install/uninstall test passed with the original ARM BusyBox shell.
The full original Lua 5.1/LuaPOSIX 5.1.19/LuaSocket 2.0.2 suite passed 55 checks,
including the added persistent-package round trip. A package-only verification
of the final staging order also passed.

One concurrent full VM run exceeded its 300-second development timeout. The
subsequent full run passed in roughly 200 seconds. No specific product defect
was established by that timeout. Private VM artifacts/logs remain ignored.

## Remaining physical verification

Before updating the test USB, uninstall the current SSH using its matching old
package. Then test a first managed installation, Exit/reboot, a later USB version,
fast status, saved uninstall and explicit Restore on the CMU. Power-loss phases
were simulated through receipt states; physical power interruption was not tested.

## Authorized vehicle follow-up

The existing port-22 service was reached first. The owner's start-ssh.sh on USB
was then started; a separate key-authenticated port-2222 connection was verified
before removing the old standalone SSH tweak. A fresh key login still succeeded
after removal. A bounded fallback was armed but was not needed.

All 67 package files were transferred and byte-verified. The first preparation
attempt refused before target changes: the factory BusyBox awk interprets the
literal backslash-t passed to -F differently from modern awk. Runtime table
readers in packages.sh and restore.sh now pass an actual tab character. The
package unit test guards against the escaped -F form, and the original-runtime
VM now uses the factory awk applet as well as the factory shell/patch/diff.

After this fix, managed SSH installation succeeded with state=installed under
/tmp/mnt/data_persist/mzd-v74-tweaks/installed/ssh/. All saved code and ownership
inventory checks passed; live service.sh, sshd_config and password.hash matched
the saved assets. Password authentication on port 22 succeeded.

The new saved uninstaller was then exercised on the vehicle: it removed both
live payload and receipt, and status returned uninstalled. Reinstallation passed
again. Final status/package-info: installed, version 0.8.1. Root, Resources and
USB were verified read-only; data_persist remains read-write as intended.
Read-only reset ordering returned ssh. Global Restore was not run on the vehicle.
The updated Lua menu started and subsequently exited normally. The temporary
port-2222 listener remains available for the ongoing test session and does not
persist across reboot. No reboot or Git push was performed in this follow-up.

The factory sshd logs an existing unsupported UsePAM option warning while
accepting its configuration. Both new port-22 logins and the service lifecycle
succeeded; no unrelated SSH configuration change was introduced during this test.

## Subsequent GUI version and patch checks

For the requested GUI version test, only the USB SSH manifest changed from
0.8.1 to 0.8.2. The owner used GUI Uninstall then Install. Observed phases:
installed 0.8.1, uninstalling, absent, installing 0.8.2, installed 0.8.2.
Saved-package verification and fresh port-22 login passed. The local SSH source
manifest remains 0.8.1; reconcile the USB-only bump before future publication.

After the owner's planned reboot, managed port 22 remained reachable. The owner
also installed Shorter List Delay; its saved package was present after reboot.
The temporary port-2222 listener ended at reboot as expected.

Before No More Disclaimer installation, complete systemApp.js matched OEM MD5
383d7e688256e09b825ced9e3eb69ee9. A RAM-only forward/reverse patch round trip
restored the original exactly. The expected complete JavaScript parsed; existing
disclaimer behavior tests passed. After the owner's GUI installation, the whole
live file matched the prepared reference exactly, MD5
f683cb5aceac11b9318c6ed17967e2ec. Its .org matched the captured original exactly.
Saved-package integrity, direct deep status and installed receipt all passed;
root and Resources were read-only. No additional live patch or uninstall was
performed by the agent. Actual disclaimer skipping still needs the subsequent
owner-operated reboot/display check.

## Local fast menu status follow-up

The menu now requests all states in one statuses call. Missing receipts return
uninstalled without launching source workers. Registered packages are checked
for state and file/path presence without hashes or patch probes. Deep checks,
including required saved providers, remain in operation preflight.

Validation passed: 50 real package adapter checks, installer UI suite including
one bulk call and no individual status calls on discovery, ShellCheck error
checks and git diff --check. Tests blocked md5sum and poisoned command workers
to verify menu status does not execute them or alter saved packages. Offline
preview rebuilt. No CMU/USB deployment or push; vehicle timing remains unmeasured.

## Publication checks

Before publishing the development changes, all 215 real worker checks passed
again, together with manifest parsing, 36 patch-order combinations, SSH supervisor,
exports, 15 Restore scenarios, restart, metrics, logging, report messages, Hello,
UI, browser transport, disclaimer behavior, validation and ShellCheck error checks.
The latest package adapter run passed all 50 checks as recorded above.

The combined emulated suite exceeded its 300-second host budget while still in
the package roundtrip. The separated transport run exposed a test client timeout
of 15 seconds, shorter than the production read-only deadline of 30 seconds.
The test client now allows 45 seconds and the overall nested-emulation host
budget is 600 seconds. Production deadlines are unchanged. Transport and package
checks can now run separately; neither timeout is counted as a passed test.

The helper-start test also needed to allow the runtime precheck before its own
startup wait. Its outer wait now allows 30 seconds; production startup behavior
is unchanged. The final separated transport run passed all 54 checks using the
original ARM Lua/POSIX/LuaSocket runtime: bulk status, Run, background jobs,
process and HTTP handling, and startup/cleanup in normal/debug/off logging modes.
No physical CMU or USB changes were made during these publication checks.
