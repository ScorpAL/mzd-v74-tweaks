# Repository instructions

Read CONTRIBUTING.md and wiki/Worker-contract.md before editing. User directions
have precedence. Runtime files live in usb/; keep developer files outside it. Target the new ready-to-run launcher only; no legacy layout or
compatibility wrappers. Use the factory Lua/POSIX/LuaSocket runtime; no custom compiled transport helpers.
Use English documentation, comments and runtime messages. Runtime is POSIX sh
and Opera-compatible ES5 JavaScript. Do not normalize binary or patch payloads.
Do not add dialogs or reboot commands to tweak workers. Status is read-only and
uses private RAM scratch space; require reasons for unavailable/broken.
Use manifest.conf as the single configuration source; never source/eval it.
Do not add checksum sidecars for project files. Preserve OEM backup fingerprints.
Run relevant contract/UI/behavior checks. Separate isolated, emulated and vehicle
evidence. Never publish vehicle dumps, private keys or personal logs.
