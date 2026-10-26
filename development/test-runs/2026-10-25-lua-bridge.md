# Local Lua backend experiment

Local-only working changes; explicitly not committed or pushed.

The private isolated VM ran the original ARM Lua 5.1, LuaPOSIX 5.1.19 and
LuaSocket 2.0.2 from the owner's dump. The completed run reported
`LUA_BACKEND_PASSED 40` and `LUA_TEST_RESULT=0`.

Covered direct fork/exec, literal argument preservation, separate stdout/stderr,
exit 2, normal exit 143 versus signal 15, exec failure, concurrent output drainage
past both 64 KiB caps, byte-preserving JSON, invalid request data, loopback HTTP,
Host/Origin/token/body checks, transport page, real installer discovery and
manifest parsing, a synthetic worker, actual background jobs and progress/output,
disconnect completion and graceful SIGTERM while a worker is active.

Both real backends were started through the new shared transport helper and
exercised through HTTP. The normal backend used the existing ARM helpers only
for regression comparison in the isolated VM. The Lua backend needed neither.
The local ready-to-copy Lua package was checked to contain zero ELF files and
no bin directory. Its UI, workers and shell adapter are shared with usb/.

Repository validation, optional-restart lifecycle tests, and existing installer
UI/transport assertions also passed. No real device command or reboot occurred.

Not established: physical CMU startup/exit behavior for Lua, Opera rendering and
controller interaction with this backend, or performance on the vehicle. Begin
the vehicle test with menu/status/system information and Log Collector. This
test package includes real workers, not simulated installation actions.

Raw VM logs and filtered proprietary runtime files remain in the ignored local
experiment cache. No OEM files, account data or keys are published.

## Vehicle follow-up and diagnostic build 2

Owner reported a failure while statuses were being checked, likely at the second
item, and inability to exit. Copied logs establish Lua/backend/UI startup but did
not record per-worker results, so the physical failure cause remains unproven.

The local diagnostic build adds action/ID/PID, heartbeat, exit/signal and bounded
failure-output logging. A stdin descriptor collision was fixed independently.
Only recognized read-only status calls receive a 30-second process-group deadline;
mutating operations have no cancellation timer. Exit is available during scans and
stops further requests; restart cannot bypass a pending/critical status result.

A fresh isolated VM run passed 48 checks, now also exercising the original CMU
BusyBox shell and patch applet against synthetic target data, initially closed
stdin, read-only deadlines including closed output streams, and both backends.
UI assertions and restart lifecycle checks passed. This does not establish that
the original vehicle error has been fixed. Diagnostic build 2 is copied into the
local USB test folder; new vehicle logs are needed. All changes remain uncommitted
and unpushed. The owner's copied logs were retained outside Git.

## Vehicle follow-up and promotion to the production package

Live SSH inspection confirmed all nine status queries completed successfully
with exit 0, without worker stderr. SSH was correctly detected as installed.
OEM-identical patch targets now skip full patch probing; measured patch status
calls on the vehicle completed in zero to one seconds. The header was reduced
to CPU/System/Resources and the redundant footer legend removed.

An isolated RAM copy on the CMU verified selective SSH hook uninstall/install
with the hook after the original blank line, preserving the live startup file
and running listener. Real SSH Wi-Fi boot tests are recorded separately in
2026-10-25-ssh-wifi-boot.md. The initial reported scan failure's cause remains
unproven; these are later successful observations.

The owner subsequently authorized promotion and pushing Lua as the sole
transport. Sources now live in usb/lib/lua-bridge/, with original-runtime tests
in tests/transport/. ARM executables, native source and compile script were
removed from the current tree. The new normal/debug/off logging configuration
reduces USB writes; this exact logging configuration is covered by isolated
checks, not an additional physical vehicle run. Private raw logs stay excluded.

Final isolated promotion checks: 54 original-runtime Lua/process/HTTP/job checks
passed, including quiet normal/off logging and detailed debug traces through the
production startup helper. Manifest parsing, 36 shared-target combinations,
SSH supervisor, export commands/jobs, restore, restart lifecycle, metrics, Hello,
logging configuration/snapshots, UI, browser transport and disclaimer behavior
also passed locally. CI now checks Lua 5.1 syntax and logging configuration.

The complete worker suite passed 207 real-entrypoint checks before promotion.
