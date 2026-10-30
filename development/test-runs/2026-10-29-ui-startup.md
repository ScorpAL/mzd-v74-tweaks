# UI startup correction for the cross-test package

Reported vehicle log: Lua transport starts, Secondary Opera remains alive, but
no UI ready event arrives within 30 seconds. That places the observed failure
before tweak discovery/install; it does not implicate the cluster worker.

Two settings callbacks were FunctionDeclarations inside if blocks under strict
mode. Modern Node executed these in our DOM tests. Such statement-context
declarations are outside the supported strict ES5 grammar; the original CMU
Opera binary also contains the diagnostic "FunctionDeclaration in Statement
context". They are now function expressions assigned before use. This fixes a
concrete compatibility defect consistent with the reported startup failure;
Piotr's actual Opera error output/vehicle retest is still needed for confirmation.

An independent inline bootstrap, loaded before app.js, now forwards uncaught
script/parse errors through the existing iframe bridge as event ui-error. It can
initialize the iframe when app.js fails before doing so. It validates origin,
source and token, caps error reports, strips URL fragments and never creates a
ready marker. Normal launcher cleanup saves the diagnostics in USB ui.log.

Checks passed:
- Runtime ES5 grammar plus a separate no-statement-context-function-declarations
  gate, including all inline scripts. The negative fixture is rejected.
- Early parse/runtime error reporting, independent transport initialization,
  source/origin/token validation, normal startup and error-report bound.
- Actual installer event ui-error writes ui.log without ready/close markers.
- Existing UI and transport suites, ten-tweak validation, error-level ShellCheck
  and git diff --check.
- Newly named 2026-10-29 USB ZIP: all ten tweaks, ZIP integrity and every packaged
  runtime file byte-compared against the working tree. No runtime logs or temp SSH.

No CMU connection or real Opera render test occurred in this correction. The
timeout is unchanged. Installer/tweak mutation logic and the compiled library
are unchanged; the long native shell lifecycle test was not repeated for a
JavaScript-only compatibility fix and an additional diagnostic event.
