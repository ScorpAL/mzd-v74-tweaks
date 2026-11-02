"""Contract test for the car's date and time: usb/lib/datetime.sh (see development/CMU-time.md).

What is tested, with a fake RTC, a fake /proc/uptime and a fake dbus-send (GetClock):
- names and Start lines in the car's local time, in UTC with Z when the zone is unknown, and
  nodate-u<uptime> when the RTC is reset, unreadable or missing;
- file dates: the car's local time, only for the given paths (and below them with -r), never
  through symbolic links, and a new reading at the end (name and Start share one snapshot);
- at most one bounded D-Bus question per launcher session; children inherit the answer;
- report.sh, the launcher (autorun.sh) and `installer.sh event` with and without datetime.sh;
- the inline copy in the SSH service: same offset checks, and logging never stops the service;
- the helper is read only: it never sets a clock.

Run it like the other contract tests:
    python3 tests/contract/test_datetime.py
"""

import calendar
import os
import re
import shlex
import shutil
import subprocess
import tempfile
import textwrap
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SHELL = "C:/Program Files/Git/bin/bash.exe" if os.name == "nt" else "/bin/sh"

# The fake car: RTC (real UTC) 2026-11-01 16:49:39, 228 s after power-on.
RTC = 1793551779
UPTIME = "228.53 400.00\n"
# The car's zone in most scenarios: +4:00, so the local time is 20:49:39.
OFFSET = 14400
LOCAL_NAME = "20261101-204939"
UTC_NAME = "20261101-164939Z"
NODATE_NAME = "nodate-u228"
LOCAL_START = "Start: 2026-11-01 20:49:39 local (UTC 16:49:39, zone +4:00), 228 s after power-on"
UTC_START = "Start: 2026-11-01 16:49:39 UTC (car zone not known yet), 228 s after power-on"
NODATE_START = "Start: no date (car clock not set), 228 s after power-on"
# A file date that must never change (copied files, symlink targets).
OLD_MTIME = 1000

# The system paths datetime.sh reads; the sandbox replaces them with fake files.
RTC_PATH = "/sys/class/rtc/rtc0/since_epoch"
UPTIME_PATH = "/proc/uptime"
SOURCE = (ROOT / "usb/lib/datetime.sh").read_text(encoding="utf-8")
SERVICE = (ROOT / "usb/tweaks/ssh/assets/service.sh").read_text(encoding="utf-8")

# Offsets given to both datetime.sh and the SSH service copy, with the expected verdict.
OFFSET_INPUTS = {
    "14400": True,
    "-12600": True,
    "0": True,
    "0900": False,  # octal in ash: would stop the service
    "0700": False,  # octal in ash: a silently wrong zone
    "3601": False,  # not a quarter hour
    "-0": False,
    "-0900": False,
    "+3600": False,
    "50400": True,  # +14:00, the largest zone
    "50401": False,
    "": False,
}
# Prints "<input>=<datetime.sh verdict>/<service copy verdict>" for every input.
OFFSET_PROBE = textwrap.dedent(
    """\
    for x in {inputs}; do
        if mzd_datetime_offset_ok "$x"; then lib=yes; else lib=no; fi
        MZD_DATETIME_OFFSET=$x
        time_line
        case "$TIME_NAME" in *Z) copy=no ;; *) copy=yes ;; esac
        echo "$x=$lib/$copy"
    done
    """
).format(inputs=" ".join(shlex.quote(value) for value in OFFSET_INPUTS))
OFFSET_EXPECTED = [
    "{0}={1}/{1}".format(value, "yes" if ok else "no") for value, ok in OFFSET_INPUTS.items()
]


def bp(path):
    """Path as the shell sees it (Git Bash drive letters on Windows)."""
    text = Path(path).resolve().as_posix()
    if len(text) > 1 and text[1] == ":":
        return "/" + text[0].lower() + text[2:]
    return text


def write(path, text, mode=0o644):
    """Write a file with Unix line ends and the given mode."""
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8", newline="\n")
    path.chmod(mode)


def mtime(path):
    """Whole-second modification time of a path."""
    return int(path.stat().st_mtime)


def local_epoch(*fields):
    """Epoch whose UTC digits are the given local time (FAT stores the local digits)."""
    return calendar.timegm(fields)


def digits(epoch, fmt):
    """An epoch formatted as UTC digits."""
    return time.strftime(fmt, time.gmtime(epoch))


def service_function(rtc, uptime):
    """The time_line() function of the SSH service as shipped, reading the given files."""
    match = re.search(r"^time_line\(\) \{\n.*?^\}\n", SERVICE, re.S | re.M)
    assert match, "service.sh has no time_line() function"
    return match.group(0).replace(RTC_PATH, rtc).replace(UPTIME_PATH, uptime)


class Sandbox:
    """A temporary USB tree with a fake RTC, uptime and dbus-send; counts the shell runs."""

    def __init__(self, base):
        self.base = base
        self.usb = base / "usb"
        self.bins = base / "bin"
        self.rtc = base / "rtc"
        self.uptime = base / "uptime"
        self.reply = base / "reply"
        self.calls = base / "calls"
        self.files = base / "files"
        self.outside = base / "outside.txt"
        self.checks = 0
        shutil.copytree(ROOT / "usb/lib", self.usb / "lib")
        self.install_datetime()
        mounts = base / "mounts"
        write(mounts, f"mock {bp(self.usb)} vfat rw 0 0\n")
        report = self.usb / "lib/report.sh"
        write(report, report.read_text().replace("/proc/mounts", bp(mounts)))
        # BusyBox syntax only: GNU "timeout 2" would be refused here.
        self.tool("timeout", '[ "$1" = -t ] || exit 125\nshift 2\nexec "$@"\n')
        calls = shlex.quote(bp(self.calls))
        reply = shlex.quote(bp(self.reply))
        self.tool("dbus-send", f'echo "$*" >> {calls}\n[ -f {reply} ] || exit 1\ncat {reply}\n')
        self.tool("mount", "exit 0\n")
        self.tool("sync", "exit 0\n")
        self.env = dict(os.environ, PATH=bp(self.bins) + ":/usr/bin:/bin")
        self.env.pop("MZD_DATETIME_OFFSET", None)
        self.env.pop("MZD_DATETIME_ASKED", None)
        self.set_uptime(UPTIME)

    def tool(self, name, body, folder=None):
        """A fake command in the sandbox PATH (or in another folder)."""
        write((folder or self.bins) / name, "#!/bin/sh\n" + body, 0o755)

    def install_datetime(self):
        """(Re)install datetime.sh so that it reads the fake RTC and uptime files."""
        text = SOURCE.replace(RTC_PATH, bp(self.rtc)).replace(UPTIME_PATH, bp(self.uptime))
        write(self.usb / "lib/datetime.sh", text)

    def set_uptime(self, text):
        """Content of the fake /proc/uptime."""
        write(self.uptime, text)

    def car(self, rtc=RTC, local=None, garbage=False):
        """Reset the fake car: the RTC value (None: missing) and GetClock's local time.

        local=None makes dbus-send fail (service silent); garbage=True sends a bad reply.
        """
        for path in [self.rtc, self.reply, self.calls]:
            if path.exists():
                path.unlink()
        if rtc is not None:
            write(self.rtc, f"{rtc}\n")
        if local is not None:
            value = "x" if garbage else str(local)
            write(
                self.reply,
                "method return time=1.0 sender=:1.7 -> destination=:1.9 serial=5\n"
                f"   uint32 20\n   uint32 49\n   uint32 {value}\n   uint64 0\n",
            )

    def queries(self):
        """Number of dbus-send runs since the last car()."""
        if not self.calls.exists():
            return 0
        return len(self.calls.read_text().splitlines())

    def run(self, script, extra=None, source_lib=True):
        """Run a shell script (datetime.sh loaded first) and return its stdout lines."""
        lib = f". {shlex.quote(bp(self.usb / 'lib/datetime.sh'))}\n" if source_lib else ""
        return self._run([SHELL, "-c", "set -u\n" + lib + script], extra)

    def run_file(self, path, args=(), extra=None):
        """Run a script file of the sandbox and return its stdout lines."""
        return self._run([SHELL, bp(path), *args], extra)

    def _run(self, command, extra):
        result = subprocess.run(
            command,
            env=dict(self.env, **(extra or {})),
            capture_output=True,
            text=True,
            timeout=20,
        )
        assert result.returncode == 0, (command, result.stdout, result.stderr)
        self.checks += 1
        return result.stdout.splitlines()

    def make_files(self):
        """A small tree with a link to an outside file; returns the paths that may be dated."""
        if self.files.exists():
            shutil.rmtree(self.files)
        write(self.files / "run.log", "x\n")
        write(self.files / "nested/b.txt", "y\n")
        write(self.outside, "z\n")
        os.utime(self.outside, (OLD_MTIME, OLD_MTIME))
        os.symlink(bp(self.outside), self.files / "link")
        nested = self.files / "nested"
        return [self.files, self.files / "run.log", nested, nested / "b.txt"]

    def full_script(self):
        """init, name, Start line, recursive touch, and the offset a child process sees."""
        return textwrap.dedent(
            f"""\
            mzd_datetime_init
            mzd_datetime_name
            mzd_datetime_start
            mzd_datetime_touch -r {shlex.quote(bp(self.files))}
            sh -c 'echo "${{MZD_DATETIME_OFFSET:-none}}"'
            """
        )


def test_read_only_source(box):
    """datetime.sh and the SSH copy never set a clock; only GetClock is called."""
    forbidden = [
        r"\bdate\b[^\n|;]*\s-s\b",
        r"hwclock",
        r"rtcwake",
        r"/dev/rtc",
        r"settimeofday",
        r"\.Set",
        r"\.Reset",
        r"dbus-monitor",
    ]
    for pattern in forbidden:
        assert not re.search(pattern, SOURCE), f"datetime.sh must not contain {pattern}"
    methods = set(re.findall(r"com\.jci\.\w+\.\w+", SOURCE))
    assert methods == {"com.jci.BLM_TIME.GetClock"}, f"unexpected D-Bus methods: {methods}"
    clock = re.search(r"hwclock|rtcwake|/dev/rtc|date -s", SERVICE)
    assert not clock, "service.sh must not set a clock"


def test_local_name_and_start(box):
    """Valid RTC and GetClock: local name and Start line, local file dates, one question."""
    for offset, zone in [(14400, "+4:00"), (-12600, "-3:30"), (20700, "+5:45"), (0, "+0:00")]:
        box.car(local=RTC + offset + 37)
        paths = box.make_files()
        name, start, child = box.run(box.full_script())
        local = RTC + offset
        expected_start = (
            f"Start: {digits(local, '%Y-%m-%d %H:%M:%S')} local (UTC 16:49:39, zone {zone}), "
            "228 s after power-on"
        )
        assert name == digits(local, "%Y%m%d-%H%M%S"), f"local name for zone {zone}: {name}"
        assert start == expected_start, f"Start line for zone {zone}: {start}"
        assert child == str(offset), f"a child process inherits the offset: {child}"
        assert box.queries() == 1, f"one D-Bus question, not {box.queries()}"
        calls = box.calls.read_text()
        assert "unix:path=/tmp/dbus_hmi_socket" in calls, "GetClock goes to the HMI bus"
        assert "--reply-timeout=" in calls, "GetClock has a reply time limit"
        for path in paths:
            assert mtime(path) == local, f"{path} has the local time as its date"
        assert mtime(box.outside) == OLD_MTIME, "a symlink target must not be touched"
        box.car(local=RTC + offset + 37)
        asked = box.run("mzd_datetime_init\nsh -c 'echo \"$MZD_DATETIME_ASKED\"'")
        assert asked == ["1"], "children inherit MZD_DATETIME_ASKED=1 and never ask again"


def test_inherited_offset(box):
    """A known offset from the launcher is reused without D-Bus; an invalid one is ignored."""
    script = "mzd_datetime_init\nmzd_datetime_name"
    box.car(local=RTC + 99999)
    name = box.run(script, {"MZD_DATETIME_OFFSET": "3600"})
    assert name == ["20261101-174939"], f"inherited offset +1:00: {name}"
    assert box.queries() == 0, "an inherited offset needs no D-Bus question"
    for bad in ["abc", "-", "3601", "99000", "--900", "0900"]:
        box.car(local=RTC + 7200)
        name = box.run(script, {"MZD_DATETIME_OFFSET": bad})
        assert name == ["20261101-184939"], f"invalid inherited offset {bad!r} is ignored: {name}"
        assert box.queries() == 1, f"invalid inherited offset {bad!r}: ask once"


def test_utc_when_zone_unknown(box):
    """RTC valid; D-Bus silent, garbage or implausible: UTC with Z and no file dates."""
    for local, garbage in [(None, False), (RTC, True), (RTC + 15 * 3600, False)]:
        case = f"reply={local} garbage={garbage}"
        box.car(local=local, garbage=garbage)
        paths = box.make_files()
        before = [mtime(path) for path in paths]
        name, start, child = box.run("mzd_datetime_init\n" + box.full_script())
        assert name == UTC_NAME, f"{case}: {name}"
        assert start == UTC_START, f"{case}: {start}"
        assert child == "none", f"{case}: an unknown offset is not passed on"
        assert box.queries() == 1, f"{case}: two inits still ask only once"
        assert [mtime(path) for path in paths] == before, f"{case}: no dates without local time"


def test_single_bounded_query(box):
    """MZD_DATETIME_ASKED=1 (exported by the launcher) means: never ask D-Bus."""
    box.car(local=RTC + OFFSET)
    assert box.run("mzd_datetime_init", {"MZD_DATETIME_ASKED": "1"}) == [], "init prints nothing"
    assert box.queries() == 0, "MZD_DATETIME_ASKED=1 must skip the D-Bus question"


def test_no_date(box):
    """RTC reset (battery), unreadable or missing: nodate name, no question, no file dates."""
    for value in [1000, 1659311999, "garbage", "", None]:
        box.car(rtc=value, local=RTC)
        paths = box.make_files()
        before = [mtime(path) for path in paths]
        name, start, child = box.run(box.full_script())
        assert name == NODATE_NAME, f"RTC {value!r}: {name}"
        assert start == NODATE_START, f"RTC {value!r}: {start}"
        assert box.queries() == 0, f"RTC {value!r}: no D-Bus question without a date"
        assert child == "none", f"RTC {value!r}: no offset is passed on"
        assert [mtime(path) for path in paths] == before, f"RTC {value!r}: no file dates"
    box.set_uptime("garbage\n")
    box.car(rtc=None)
    assert box.run("mzd_datetime_name") == ["nodate-u0"], "an unreadable uptime counts as 0"
    box.set_uptime(UPTIME)


def test_unique_names(box):
    """Two names in the same second stay unique through mktemp."""
    box.car(local=RTC + OFFSET)
    out = box.base / "out"
    out.mkdir()
    folder = shlex.quote(bp(out))
    script = textwrap.dedent(
        f"""\
        mzd_datetime_init
        name=$(mzd_datetime_name)
        mktemp -d {folder}/"$name-XXXXXX"
        mktemp -d {folder}/"$name-XXXXXX"
        """
    )
    first, second = box.run(script)
    assert first != second, "mktemp makes the two folders differ"
    for path in [first, second]:
        assert Path(path).name.startswith(LOCAL_NAME + "-"), f"local name: {path}"


def run_report(box, extra=None):
    """A report.sh session that also copies an old file into its report; returns the folder."""
    old_copy = box.base / "old.org"
    write(old_copy, "backup\n")
    os.utime(old_copy, (OLD_MTIME, OLD_MTIME))
    copy = shlex.quote(bp(old_copy))
    driver = textwrap.dedent(
        f"""\
        ROOT={shlex.quote(bp(box.usb))}
        MZD_ORIGIN_USB=$ROOT
        ACTION=install
        . "$ROOT/lib/report.sh"
        mzd_begin "$ROOT/tweaks/demo/run.sh" demo
        MZD_SUCCESS=done
        echo work
        mkdir "$MZD_REPORT/backups"
        cp -p {copy} "$MZD_REPORT/backups/target.org"
        cp -p {copy} "$MZD_REPORT/payload.data"
        """
    )
    if (box.usb / "reports").exists():
        shutil.rmtree(box.usb / "reports")
    assert box.run(driver, extra, source_lib=False) == ["done"], "report.sh announces success"
    found = list((box.usb / "reports/demo").iterdir())
    assert len(found) == 1, f"one report folder: {found}"
    return found[0]


def test_own_files_only(box):
    """report.sh: name and Start from one snapshot; only the report's own files are dated."""
    box.car(local=RTC + OFFSET)
    folder = run_report(box)
    assert re.fullmatch(rf"install-{LOCAL_NAME}-\w{{6}}", folder.name), folder.name
    log = (folder / "run.log").read_text().splitlines()
    assert log[0] == LOCAL_START, f"run.log starts with the Start line: {log}"
    assert log[1].startswith("Installer version:"), f"then the installer version: {log}"
    assert log[-1] == "done", f"and ends with the success line: {log}"
    finished = local_epoch(2026, 11, 1, 20, 49, 39)
    for path in [folder, folder / "run.log", folder / "status.txt"]:
        assert mtime(path) == finished, f"{path} has the local time as its date"
    for path in [folder / "backups/target.org", folder / "payload.data"]:
        assert mtime(path) == OLD_MTIME, f"copied file {path} keeps its own date"


def test_worker_never_asks(box):
    """A worker started by the launcher (MZD_DATETIME_ASKED=1, no offset) never asks D-Bus."""
    box.car(local=RTC + OFFSET)
    folder = run_report(box, {"MZD_DATETIME_ASKED": "1"})
    assert re.fullmatch(rf"install-{UTC_NAME}-\w{{6}}", folder.name), folder.name
    assert box.queries() == 0, f"the worker asked D-Bus {box.queries()} times"


def test_launcher_exports_asked(box):
    """The real launcher start asks once and passes MZD_DATETIME_ASKED=1 (and the offset) on."""
    launcher = (ROOT / "usb/autorun.sh").read_text()
    start_line = 'mzd_datetime_start > "$STATE/launcher.log"\n'
    end = launcher.index(start_line) + len(start_line)
    assert end < launcher.index("mzd_transport_start"), "the launcher asks before any worker"
    shutil.copyfile(ROOT / "usb/VERSION", box.usb / "VERSION")
    session = box.usb / "lib/session.sh"
    write(session, session.read_text().replace(
        "MZD_SESSION_DIR=/tmp/mzd-installer-session",
        "MZD_SESSION_DIR=" + shlex.quote(bp(box.base / "launcher-session")),
    ))
    tail = textwrap.dedent(
        """\
        sh -c 'echo "$MZD_DATETIME_ASKED ${MZD_DATETIME_OFFSET:-none}"'
        echo "${LOG_DIR##*/}"
        cat "$STATE/launcher.log"
        rm -rf "$STATE"
        """
    )
    write(box.usb / "autorun.sh", launcher[:end] + tail, 0o755)
    cases = [(RTC + OFFSET, f"1 {OFFSET}", LOCAL_NAME), (None, "1 none", UTC_NAME)]
    for local, expected, name in cases:
        box.car(local=local)
        # Inspect the real session child; detachment itself has a separate test.
        child, log_dir, start = box.run_file(box.usb / "autorun.sh", ["--session"])
        assert child == expected, f"environment for workers: {child}"
        assert box.queries() == 1, f"the launcher asks once, not {box.queries()} times"
        assert log_dir.startswith(name + "-"), f"installer-logs folder name: {log_dir}"
        assert start.startswith("Start: "), f"launcher.log starts with the Start line: {start}"


def test_installer_event_without_lib(box):
    """installer.sh event: Start line on a new ui.log; without datetime.sh it still works."""
    shutil.copyfile(ROOT / "usb/installer.sh", box.usb / "installer.sh")
    try:
        for present in [True, False]:
            if not present:
                (box.usb / "lib/datetime.sh").unlink()
            state = box.base / f"state-{present}"
            state.mkdir()
            box.car(local=RTC + OFFSET)
            extra = {
                "INSTALLER_STATE": bp(state),
                "INSTALLER_LOG": bp(state),
                "MZD_DATETIME_OFFSET": str(OFFSET),
            }
            box.run_file(box.usb / "installer.sh", ["event", "note", "hello"], extra)
            lines = (state / "ui.log").read_text().splitlines()
            assert lines[-1].endswith(" note hello"), f"datetime.sh present={present}: {lines}"
            assert box.queries() == 0, "a UI event never asks D-Bus"
            if present:
                assert lines[0] == LOCAL_START, f"ui.log starts with the Start line: {lines}"
            else:
                assert len(lines) == 1, f"without datetime.sh only the event line: {lines}"
    finally:
        box.install_datetime()


def test_snapshot_and_new_touch_reading(box):
    """Name and Start share one snapshot; touch takes a new reading (the end time)."""
    box.car(local=RTC + OFFSET)
    box.make_files()
    script = textwrap.dedent(
        f"""\
        mzd_datetime_snapshot
        echo {RTC + 75} > {shlex.quote(bp(box.rtc))}
        echo 303.2 0 > {shlex.quote(bp(box.uptime))}
        mzd_datetime_name
        mzd_datetime_start
        mzd_datetime_touch {shlex.quote(bp(box.files / "run.log"))}
        mzd_datetime_read
        """
    )
    name, start, now = box.run(script)
    box.set_uptime(UPTIME)
    assert name == LOCAL_NAME, f"the name comes from the snapshot: {name}"
    assert start == LOCAL_START, f"the Start line comes from the snapshot: {start}"
    assert now == f"local {RTC + 75} {RTC + 75 + OFFSET} 303", f"a new reading: {now}"
    end = local_epoch(2026, 11, 1, 20, 50, 54)
    assert mtime(box.files / "run.log") == end, "touch uses the end time, not the snapshot"
    assert mtime(box.files / "nested/b.txt") != end, "without -r only the given paths are dated"


def test_service_copy_same_inputs(box):
    """The SSH service's inline copy accepts exactly the offsets that datetime.sh accepts."""
    function = service_function(bp(box.rtc), bp(box.uptime))
    box.car()
    verdicts = box.run("set -e\n" + function + OFFSET_PROBE)
    assert verdicts == OFFSET_EXPECTED, f"datetime.sh and service.sh disagree: {verdicts}"


def test_service_survives_bad_date(box):
    """A failing date never stops the service (set -eu): the log just has no date."""
    function = service_function(bp(box.rtc), bp(box.uptime))
    broken = box.base / "broken-bin"
    box.tool("date", "exit 1\n", broken)
    box.car()
    for offset in [str(OFFSET), ""]:
        script = textwrap.dedent(
            f"""\
            MZD_DATETIME_OFFSET={offset}
            time_line
            echo "$TIME_NAME|$TIME_START"
            """
        )
        lines = box.run(
            "set -e\n" + function + script, {"PATH": bp(broken) + ":" + box.env["PATH"]}
        )
        assert lines == [f"{NODATE_NAME}|{NODATE_START}"], f"offset {offset!r}: {lines}"


SCENARIOS = [
    test_read_only_source,
    test_local_name_and_start,
    test_inherited_offset,
    test_utc_when_zone_unknown,
    test_single_bounded_query,
    test_no_date,
    test_unique_names,
    test_own_files_only,
    test_worker_never_asks,
    test_launcher_exports_asked,
    test_installer_event_without_lib,
    test_snapshot_and_new_touch_reading,
    test_service_copy_same_inputs,
    test_service_survives_bad_date,
]


def main():
    with tempfile.TemporaryDirectory(prefix="cmu-time-") as directory:
        box = Sandbox(Path(directory))
        for scenario in SCENARIOS:
            scenario(box)
        checks = box.checks
    print(
        f"DATETIME_PASSED: {checks} checks: local/UTC/no-date names, Start lines, own-file dates, "
        "one snapshot, single bounded query, launcher/worker/installer event, service.sh copy."
    )


if __name__ == "__main__":
    main()
