# Vehicle testing

Use development/test-runs/TEMPLATE.md to record a run on the exact commit and firmware.
Keep test type explicit: isolated fixtures, emulation or physical CMU. Include
install, status, actual behavior, uninstall and restoration checks. Persistence
requires a separate full reboot test. Do not mark it passed just because a
service started once. Reproduction steps and sanitized summaries belong in Git;
private dumps, keys and unfiltered logs do not.
