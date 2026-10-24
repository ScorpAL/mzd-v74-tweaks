# Repository instructions

Read CONTRIBUTING.md and wiki/Worker-contract.md before editing. User directions
have precedence. Target the new ready-to-run launcher only; no legacy layout or
compatibility wrappers. Keep executable ARM helpers checked in alongside source.
Use English documentation, comments and runtime messages. Runtime is POSIX sh
and Opera-compatible ES5 JavaScript. Do not normalize binary or patch payloads.
Do not add dialogs or reboot commands to tweak workers. Status is read-only and
uses private RAM scratch space; require reasons for unavailable/broken.
Keep script/asset checksums, manifests and dependency declarations consistent.
Run relevant contract/UI/behavior checks. Separate isolated, emulated and vehicle
evidence. Never publish vehicle dumps, private keys or personal logs.
