# Package action performance (issue #52)

Working branch: `perf/issue-52-package-actions`, baseline: `d74b1f4`.

## Measurement and reporting

Compare baseline, inventory batching, and operation-local reuse in the same
container image, on the same machine, with the same fixtures and installed
packages. Keep native Linux/container results, ARM emulation and physical CMU
results separate. Docker setup and image builds are excluded from action times.

Report repeated measurements (warm-up followed by at least five measured runs)
and their median, along with process counts. Keep the initial installed state
and action order identical. Include Tetris, Snake and Minesweeper installed for
the Snake Update comparison from issue #52.

Use these columns in the PR:

| Scope | Baseline | After step 1 | Final | Reduction vs baseline |
| --- | ---: | ---: | ---: | ---: |
| Inventory hash command starts | pending | pending | pending | pending |
| Inventory elapsed time | pending | pending | pending | pending |
| Tetris Install | pending | pending | pending | pending |
| Snake Install (second consumer) | pending | pending | pending | pending |
| Minesweeper Install (third consumer) | pending | pending | pending | pending |
| Snake Update (all three installed) | pending | pending | pending | pending |
| Snake Uninstall | pending | pending | pending | pending |
| Complete measured action sequence | pending | pending | pending | pending |

Time reduction (%) = `100 * (baseline - measured) / baseline`.
Process reduction uses the same formula. Always label whether the percentage
refers to elapsed time or process starts. Do not describe fewer processes as
an equivalent runtime improvement.

Calculate the overall time reduction from the baseline and final sums of the
same action sequence, not by adding or averaging individual percentages.
Also distinguish each step's incremental improvement from the final improvement
against the original baseline. Negative values indicate a regression.

## Preliminary evidence

The isolated QEMU tests confirmed unchanged inventory bytes and error handling,
87 package lifecycle checks and 12 three-game lifecycle actions. These are
correctness evidence, not the final Docker performance measurements.

The earlier 198-file synthetic fixture reduced md5sum command starts from 198
to 4 (97.98%). Its emulator timings were collected under concurrent load and
must not be used as the final runtime improvement. The controlled fixture now
uses 197 files; new measurements supersede those preliminary numbers.

Implementation and final measurement are in progress; no CMU speedup is claimed.
