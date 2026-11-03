# Package action performance (issue #52)

Working branch: `perf/issue-52-package-actions`, baseline: `d74b1f4`.

## Measurement and reporting

Compare baseline, inventory batching, and operation-local reuse in the same
container image, on the same machine, with the same fixtures and installed
packages. Keep native Linux/container results, ARM emulation and physical CMU
results separate. Docker setup and image builds are excluded from action times.

Report one complete run per candidate, along with PID allocation deltas as a
process-count proxy. These are indicative measurements, not statistically
validated estimates. Additional repetitions are optional, not the default. Keep the initial installed state
and action order identical. Include Tetris, Snake and Minesweeper installed for
the Snake Update comparison from issue #52.

Use these columns in the PR:

| Scope | Baseline | After step 1 | Final | Time reduction vs baseline |
| --- | ---: | ---: | ---: | ---: |
| tetris install | 1.163 s | 1.002 s | 0.847 s | 27.2% |
| snake install | 2.701 s | 1.448 s | 1.227 s | 54.6% |
| minesweeper install | 3.377 s | 2.033 s | 1.557 s | 53.9% |
| snake update | 6.405 s | 4.438 s | 3.183 s | 50.3% |
| snake uninstall | 2.401 s | 1.359 s | 1.132 s | 52.8% |
| **Complete action sequence** | **16.047 s** | **10.279 s** | **7.946 s** | **50.5%** |

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

## Implementation

Step 1 batches hashes with NUL-separated arguments and preserves the existing
inventory format. Producer failures are checked before parsing the hash output.

Step 2 reuses successful full package verification only inside the locked
controller and the current mutation-free phase. The context is private RAM,
not inherited from the caller or exported to workers. Every state write and
worker boundary discards verification results. Failed checks are never cached.
Repeated manifest parsing inside a full check and an immediate duplicate load
in Update are removed; other loads keep their validation. No persistent cache
or executable serialization of manifest data is introduced.

## Single-run Docker results

The table above records one complete run of each implementation on the same
machine and Docker image. Raw values and per-action percentages are in
[issue52-docker.json](performance/issue52-docker.json). Build/setup time and
fixture preparation/cleanup are excluded; each measured action is validated
by the existing three-game fixture. This is native Linux/container evidence,
not ARM or vehicle timing.

Step 1 reduced the measured action-sequence time by 35.9%.
Step 2 reduced the remaining time by 22.7% relative to step 1.
The combined time reduction was **50.5%** against the original baseline.
PID allocation delta fell from 12039 to 7533 (**37.4%**).

Tetris Install allocates slightly more PIDs than batching alone (845 vs 835):
the operation context has some overhead, while a first install has little
repeated verification. The complete sequence still allocates fewer PIDs.
Single-run timings include cache/order effects and normal measurement noise.
Do not add the two stage percentages or claim the same improvement on a CMU.
No physical CMU speedup has been measured yet.
