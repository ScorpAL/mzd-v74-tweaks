# No More Disclaimer verification

- `node tests/tweaks/no-more-disclaimer/behavior.cjs`: evaluates the actual context
  from the shipped diff and checks template/properties, immediate MMUI event order
  and absence of the old dialog/timer callbacks. Included in CI.
- `CMU_TEST_ONLY=no-more-disclaimer python tests/contract/test_workers.py`: real
  entrypoint against isolated synthetic fixtures, including states, dependencies,
  actions, unrelated edits, write failure, rollback and cleanup severity.
- `python tests/tweaks/no-more-disclaimer/test_port.py ORIGINAL MODIFIED`: optional
  check against the complete verified OEM and upstream v74 JavaScript files.
  These input files are deliberately not shipped or required by CI.

All these checks are isolated and do not prove physical CMU startup behavior.
