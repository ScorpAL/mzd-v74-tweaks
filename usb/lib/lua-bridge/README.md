# CMU Lua transport

Runs on the factory Lua 5.1, LuaPOSIX 5.1.19 and LuaSocket 2.0.2 runtime.
No downloaded modules or custom ARM executables are needed on the CMU.

- server.lua: loopback HTTP on a random port; session token and Host/Origin checks.
- process.lua: direct fork/exec, concurrent output capture, exit/signal handling.
- protocol.lua: request arguments and byte-preserving JSON encoding for the UI.

Arguments stay separate; no os.execute, io.popen or shell command concatenation.
Both output streams are bounded at 64 KiB. A disconnect or server termination
does not abort an active modifying worker. Only recognized read-only status
requests have a 30-second deadline and their own process group, with TERM then
KILL after two seconds. Install/uninstall/restore/Run are never timed out here.

Detailed HTTP/process diagnostics require logging=debug in installer.conf.
Normal operation records startup/shutdown and concise process errors in RAM;
the launcher saves session logs on Exit/failure. Off disables USB diagnostics.

The transport and styled menu are separate processes. The existing installer
and tweak contract remains unchanged. No permanent transport daemon is installed.
See tests/transport/ for the original-runtime VM tests and tests/runs/ for vehicle
evidence. This implementation was inspired by the LuaSocket example in
AutoX System Tools; it does not use that example's CGI routing.
