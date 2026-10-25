# No More Disclaimer port validation

- Date: 2026-10-25
- Revision: the commit containing this record; base `dc02dea`
- Type: isolated local tests, not physical CMU
- Target firmware: 74.00.324
- Upstream reference: piotrmocko/mzd-v74-tweaks at
  `8b329eb9ffc7ce322786b2ad9980d37b887f4adc`

| Check | Result |
| --- | --- |
| Manifest validation and automatic installer discovery | Passed; six tweaks listed |
| Real worker entrypoint with isolated paths/commands | 32 checks passed |
| Status, install, uninstall and repeated actions | Passed |
| Unsupported/partial states, dependencies and inspection failures | Passed |
| Unrelated changes retained through uninstall | Passed |
| Failed write, failed rollback and cleanup severity | Passed |
| Shipped context evaluated in Node VM | Correct NoCtrlTmplt properties and exact three-event sequence; no timer |
| Complete verified OEM systemApp.js plus upstream active context | Exact intended context replacement and no other changes |
| Complete-file reverse patch | Original bytes restored exactly |
| Complete-file edits before and after installing | Preserved exactly on uninstall |

The worker tests use the shared fixture suite through Git Bash on Windows. The
behavior test uses a mocked framework and does not run the CMU browser. Full-OEM
inputs were read from the upstream reference, validated against the manifest's
OEM fingerprint, used only in a disposable local directory and not committed.

The diff contains only the active v74 context change; the upstream commented
copy of the old dialog is omitted. No complete original/replacement JavaScript
file is shipped. The port still requires a physical CMU startup test after a
manual restart, plus physical confirmation of restoration after uninstall.
