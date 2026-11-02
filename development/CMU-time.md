# Date and time on the CMU

How a tweak gets the real date and time for log names, log lines, file dates and its screen. Checked on
firmware 74.00.324.

## What to use

```sh
. "$ROOT/lib/datetime.sh"
name=$(mzd_datetime_name)        # for folder and file names
mzd_datetime_start >> "$LOG"     # first line of a log
mzd_datetime_touch "$FOLDER"     # real file dates, after the folder is complete
```

- Do **not** use `date` for dates: on the CMU it always starts at 1970. `date +%s` is fine for durations.
- Never set a clock: no `date -s`, `hwclock`, `rtcwake`, no writes to `/dev/rtc0`, no D-Bus `Set*` calls.

## The functions of `usb/lib/datetime.sh`

| Function | Prints or does | Example |
| --- | --- | --- |
| `mzd_datetime_name` | the car's local date and time for a name | `20261101-204939` |
| | when the car's zone is not known yet: UTC, marked with `Z` | `20261101-164939Z` |
| | when the car has no real date (clock not set) | `nodate-u228` (228 s after power-on) |
| `mzd_datetime_start` | one line that ties the uptime stamps of a log to the real time | `Start: 2026-11-01 20:49:39 local (UTC 16:49:39, zone +4:00), 228 s after power-on` |
| `mzd_datetime_touch PATH...` | sets the car's local time as the date of the files and folders; does nothing when it is not known | Windows shows `01.11.2026 20:49` instead of `01.01.1980` |

Add a unique part to names (`mktemp -d "…/$(mzd_datetime_name)-XXXXXX"`): two names in the same second
must differ. The functions only read; they ask the time service at most once per process, with a time
limit of a few seconds.

## Where the date and time come from

| What | Source | Notes |
| --- | --- | --- |
| Linux clock (`date`) | never set on the CMU | counts from 1970-01-01 at every start; never jumps, so good for durations |
| Real UTC | the RTC: `/sys/class/rtc/rtc0/since_epoch` | readable at once after power-on; keeps counting while the car is off |
| Car's local time (zone and DST included) | `com.jci.BLM_TIME.GetClock` on the HMI bus | `u32Timestamp` in the reply is the local time as epoch seconds; offset = it − RTC |
| Clock settings | `com.jci.settings.Get_Settings_*` on the HMI bus | 12/24 h, zone, DST, GPS sync (below) |

## Things to know

- **The RTC can be reset.** After the battery was disconnected it starts again near zero (the car then
  shows a date in 2010, see [the 2010 offset](#the-2010-offset)) until the clock is set. Any value before
  `1659312000` (2022-08-01) means "no date".
- **The car's own flags do not tell.** `com.jci.time` reports `synchronized` 1 also for the wrong 2010 date.
- **The time service can be late.** Right after power-on `GetClock` may not answer yet; then only UTC is
  known. What the time service did is in [the car's running log](#the-cars-running-log).
- **Seconds.** GPS sync sets the exact second; "Adjust Time" in Settings sets hours and minutes only, so the
  clock can be up to a minute off. The time of the last GPS fix is a lower bound for the real time (see
  [the GPS time stamp](#the-gps-time-stamp)).
- **Time zone.** A zone chosen by hand becomes active after the next restart of the car. With GPS sync on,
  the zone comes from the navigation's map data and can be wrong where the maps do not cover the country.
  Always use the time the car shows (`GetClock`), never your own zone table.
- **File dates.** The USB stick (FAT) stores local time and cannot hold dates before 1980, so files written
  with the 1970 clock show 1 Jan 1980. FAT keeps even seconds only.

## Reading the car's clock and settings yourself

For a tweak's screen: show the car's local time, in the car's 12/24 h format.

```sh
timeout -t 2 dbus-send --address=unix:path=/tmp/dbus_hmi_socket --reply-timeout=1500 --print-reply \
    --dest=com.jci.BLM_TIME /com/jci/BLM_TIME com.jci.BLM_TIME.GetClock
# reply: uint32 hours, uint32 minutes, uint32 u32Timestamp, uint64 (not used)

# Settings, read only. NAME ID: TimeFormat 173, GPS_Sync 175, TimeZone 176 (Get_Settings_U8),
# TimeDST 179 (Get_Settings_S16). The last argument is ID << 16 | 0x201, as the firmware itself asks.
timeout -t 2 dbus-send --address=unix:path=/tmp/dbus_hmi_socket --reply-timeout=1500 --print-reply \
    --dest=com.jci.settings /com/jci/settings com.jci.settings.Get_Settings_U8 \
    string:com/jci/blm/settings string:Time string:TimeFormat uint32:0 uint32:$(((173 << 16) | 0x201))
```

| Setting | Values |
| --- | --- |
| `TimeFormat` | 1 = 12 h, 2 = 24 h |
| `GPS_Sync` | 1 = on, 2 = off |
| `TimeDST` | DST in minutes: 0 or 60 |
| `TimeZone` | position of the zone in the Settings list, plus one |

## For a deeper look

Not needed for logs; useful when you investigate the clock itself.

### The GPS time stamp

`/tmp/mnt/data/lds_gps.txt` (48 bytes) is kept by the GPS service. Bytes 8 to 15 hold the UTC time of the
last GPS fix as epoch seconds (32-bit low part, then high part):

```sh
dd if=/tmp/mnt/data/lds_gps.txt bs=1 skip=8 count=8 2>/dev/null | od -A n -t u4   # e.g. 1793546602 0
```

The real time is never before this stamp, so it can tell a plausible RTC from a wrong one. It is not
updated while the car is parked. **The rest of the file holds the car's position: never log, copy or
export it.**

### The 2010 offset

While the RTC holds a small value (after a reset), the firmware shows it shifted by `1262304000` s, that
is from 2010-01-01: a reset car shows a date like 2010-01-07. Once the clock is set, the RTC holds plain
UTC (seconds since 1970) and is shown as it is. So never add or remove this offset yourself: check the RTC
against the 2022-08-01 floor instead.

### The car's running log

The firmware's services log into `/var/log/running_log/log`, with uptime stamps; about every minute the
file is packed into `log_NNNN.tar.gz` next to it. The time service writes lines such as minute events and
GPS sync changes (`BLM_TIME`, `CPP_TIME`, `GPS_Sync`):

```sh
for f in /var/log/running_log/log_*.tar.gz; do gzip -dc "$f" | tar -xOf - | grep -E 'BLM_TIME|GPS_Sync'; done
grep -E 'BLM_TIME|GPS_Sync' /var/log/running_log/log
```

The log also holds other services' data (for example Bluetooth devices): search it for what you need;
do not export it whole.

## BusyBox 1.19.2 notes

- `timeout -t 5 CMD`, not `timeout 5 CMD`.
- `date -u -d "@SECONDS" +FORMAT` and `touch -d "YYYY-MM-DD HH:MM:SS"` work; `touch -d` reads the text in
  the zone of `TZ`, which is not set on the CMU.
- Shell arithmetic is 32-bit: epoch seconds are fine until 2038.
