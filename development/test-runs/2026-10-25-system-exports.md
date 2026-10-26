# System exports and live progress

Local isolated verification; vehicle validation is pending.

- Export suite: 14 entrypoint checks, read-only source fixtures, USB mount restoration, unique outputs, archive validation and simulated archive failures; real installer background-job start/poll/output lifecycle.
- ZIP commands are host test doubles using real ZIP bytes, not a test of the CMU ZIP binary.
- UI simulation: both System commands start a job, show phase/file progress, display final output and guard Exit while running.
- Manifest parser: 19 checks; repository validator discovers eight valid workers.

Vehicle follow-up: run both tools, check progress responsiveness, validate USB archive contents and logs, confirm return to Mazda UI. Large JCI exports and live rotating logs require physical testing.
