# Log Collector

System command for firmware 74.00.324. Select **Run** in the launcher, or invoke `sh run.sh run`. `status` is read-only and returns `uninstalled` when ready (displayed as Ready), or `unavailable` with a reason on stderr.

Copies regular files from `/var/log/running_log` into `logs/`, retaining relative paths. Progress shows copied files / total files and elapsed time. Log rotation settings are unchanged. Logs remain live: if a file disappears during copying, the export fails visibly and retains its incomplete output.

Output is saved on the USB containing this worker, under `exports/logs-collector/<timestamp>-<unique>-complete/`. Each run creates a separate folder with `run.log`. Failed runs retain a folder with `.incomplete`; they are never labelled complete. The final dialog displays the output path or failure details.

The worker resolves its own location and checks the actual USB mount and available space. It may temporarily remount that USB writable and restores its original mount mode afterwards. It does not remount internal storage, stop the watchdog, install anything or reboot. Keep the USB connected until the result appears. Source data stays unchanged.

Uses shared `lib/export.sh`. `progress=true` enables RAM-based background-job polling through the existing bridge. No Python or Node.js is needed on the vehicle.
