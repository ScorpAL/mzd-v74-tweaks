# MZD branding and persistent namespace

The visible launcher title/header now reads MZD Tweaks. Saved packages and shim
payloads use /tmp/mnt/data_persist/mzd-tweaks; the SSH resource payload and its
boot hooks use /tmp/mnt/resources/mzd-tweaks/ssh. Runtime readers, developer
validators, examples, fixtures and active documentation use the same paths.
Repository URLs and historical test records retain their original names.

Checks passed: cluster-language 14, persistent package lifecycle 50, SSH worker
46, component schema 12, manifest grammar 29, ES5/early error/UI suites, runtime
validation for ten tweaks, error-level ShellCheck and git diff --check. The local
preview was rebuilt. The newly named MZD USB archive contains all ten tweaks,
has no collected output/temp SSH, and passed ZIP integrity plus byte comparison.

No CMU was modified. No new command flags or worker algorithms were introduced;
the previous original-CMU-tool runs remain historical evidence and were not
rerun for this path/title change. Existing installations are not migrated by a
directory rename. Uninstall with the previous matching USB before reinstalling:
absolute loader/boot paths, saved manifest paths and helper snapshots can retain
the old namespace; editing saved package contents invalidates their inventory.
The previous test archive is retained locally for matching removal. No automatic
migration or compatibility alias was added; nothing was pushed.
