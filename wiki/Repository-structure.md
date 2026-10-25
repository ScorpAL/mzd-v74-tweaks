# Repository structure

The `usb/` directory is the finished USB tree: autorun.sh, installer.sh, entry files,
ui/, tweaks/, installer.conf and lib/. Nothing builds or assembles this tree at startup. Copy its contents, not the enclosing folder, to the stick.

Each tweak owns its manifest, run.sh, assets and technical README. Groups are
manifest data, not an extra folder hierarchy. Shared helpers have specific roles:
report.sh, system.sh, patch.sh and status.sh. Prerequisites and tweak decisions
stay in the worker. Do not add an unspecific common/ directory.

Website sources belong in docs/. Wiki source belongs here. Technical information
specific to one tweak belongs next to that tweak. Prefer links over duplicate
hand-maintained text. tests/runs/ stores reviewed test evidence, not raw captures.
The factory Lua transport source is ready to run under usb/lib/lua-bridge/.
No custom compiled helpers or compilation step are required.
Installer diagnostics are controlled by logging=normal/debug/off in installer.conf.
