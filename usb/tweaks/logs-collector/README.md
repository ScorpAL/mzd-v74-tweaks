# Log Collector

Supported firmware: **74.00.324**. Select **System > Log Collector > Run**.
Copies available running logs to the connected USB under `exports/logs-collector/`.
Progress shows files copied and elapsed time. Keep USB connected until completion.

Each run has a separate output folder and log. Completed folders end in `-complete`;
failed runs retain incomplete output. Logs can change while copying, so a file
disappearing may cause a reported failure. Original logs and rotation settings
are left unchanged. Review logs for personal information before sharing them.
