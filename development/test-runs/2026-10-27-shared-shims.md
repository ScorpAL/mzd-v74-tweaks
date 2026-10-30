# Shared shim installation support

Scope: generic installation of an author-supplied ARM shared library through
LD_PRELOAD, using saved packages and the existing restore/report infrastructure.
No functional shim was added to the ready-to-run USB tweak list.

## Isolated checks

The shared shim suite uses synthetic loader files and header-only ELF fixtures.
It covers two libraries sharing a service, selective uninstall, matching saved
assets, immutable payload ownership, rollback after a failed second config write,
native-module compatibility checks before replacement, reset cleanup, extra
loader targets, exact text preservation and rejection of ambiguous XML.
The fixtures are never loaded as executable libraries. The final run passed
29 checks (SHIM_TRANSFORMS_PASSED), including six initial controller operations
reported by SHIM_LIFECYCLE_PASSED and the subsequent failure/reset scenarios.

Manifest tests passed 29 checks. Existing package, settings and restore suites
also passed during implementation. Repository validation passed for all nine
runtime tweaks; ShellCheck at error severity and git diff --check passed.

## Original CMU tools in emulation

The focused --shims transport test passed with the original ARM BusyBox shell,
awk, dd and od: ORIGINAL_SHIM_TOOLS_PASSED and LUA_TEST_RESULT=0. This checks
literal metadata, header validation and composition/removal of preload tokens.
It exposed an old-awk regular-expression escaping difference, which was fixed
and retested. This is tool compatibility evidence, not a CMU process boot test.

## Limits

The example contains inert C source and a developer build script. No compatible
ARM compiler was available on the host; no compiled example is supplied or
claimed to have been loaded. Real symbol interception, ABI compatibility,
physical CMU startup and interactions between functional shims remain the
responsibility of each tweak author and require separate vehicle testing.
No changes were deployed to a CMU or pushed to GitHub for this task.
