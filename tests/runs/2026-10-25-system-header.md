# System information header

Local isolated verification only; physical CMU display validation is pending.

- Actual installer metrics entrypoint with proc/df fixtures: CPU deltas (including idle+iowait and excluding double-counted guest ticks), zero/reset samples, free percentages based on available blocks, pseudo-filesystem filtering, duplicate devices, invalid arguments and read failures.
- Functional UI assertions: first CPU sample, periodic update, mounted partition labels and polling paused during a modifying operation.
- Existing transport assertions and repository validation passed.

Runtime reads /proc/stat and df -Pk, with no scratch files or USB writes. The browser retains CPU counters and polls every five seconds while idle. The first sample has no CPU percentage. Values after pauses represent the interval since the previous snapshot.

Vehicle follow-up: confirm all expected mounted block devices are listed and header text fits the 800x480 display without obscuring tabs or controls.
