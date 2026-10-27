"""Terminal entrypoint: the launcher contract of run.sh, and the refusals and patching of assets/terminal.sh.

The CMU's Lua, BusyBox `script` and Terminal are replaced by stubs, so the Lua bridge, the pseudo-terminal and the real
Terminal window are not exercised here; they need the vehicle. Each test gets its own fake CMU in a temporary folder."""

from contextlib import contextmanager
from pathlib import Path
import os
import re
import shlex
import shutil
import subprocess
import tempfile
import time

from cases import CASES

ROOT = Path(__file__).resolve().parents[2]
SHELL = "C:/Program Files/Git/bin/bash.exe" if os.name == "nt" else "/bin/sh"
assert {name for name, runner in CASES.items() if runner == "terminal-command"} == {"terminal"}

# The lines of the stock /jci/scripts/run-terminal.sh that terminal.sh replaces, between lines it leaves alone
STOCK = """#!/bin/sh
export XDG_RUNTIME_DIR=/tmp
export SHELL='/bin/sh'
echo "" > /tmp/root/weston.ini
ivi-shell -a "Wayland Terminal":255 > /dev/null &
exit 0
"""
STUB_BRIDGE = "#!/bin/sh\necho stub-bridge\n"
SUCCEEDS = "#!/bin/sh\nexit 0\n"
FAILS = "#!/bin/sh\nexit 1\n"
# `busybox --list` names the applets; the %s is the line that names `script`
BUSYBOX = '#!/bin/sh\n[ "$1" = --list ] && printf "ash\\n%ssh\\n"\n'
BUSYBOX_WITH_SCRIPT = BUSYBOX % "script\\n"
BUSYBOX_WITHOUT_SCRIPT = BUSYBOX % ""
# What autorun.sh exports for the launcher's own Opera
LAUNCHER_ENVIRONMENT = {
    "WAYLAND_IVI_SURFACE_ID": "2",
    "OPERA_HOME": "/tmp/x/opera-home/",
    "OPERA_DIR": "/x",
    "FREETYPE_FONT_SET": "YES",
}


def shell_path(path):
    """The path as the shell sees it (on Windows with Git Bash: /c/...)."""
    text = Path(path).resolve().as_posix()
    return "/" + text[0].lower() + text[2:] if len(text) > 1 and text[1] == ":" else text


def write(path, text, mode=0o644):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8", newline="\n")
    path.chmod(mode)


@contextmanager
def moved_away(path):
    """The file is missing inside the block."""
    hidden = path.with_name(path.name + ".moved")
    path.rename(hidden)
    try:
        yield
    finally:
        hidden.rename(path)


@contextmanager
def replaced(path, text, mode=0o755):
    """The file has other content inside the block."""
    old_text, old_mode = path.read_text(), path.stat().st_mode
    write(path, text, mode)
    try:
        yield
    finally:
        write(path, old_text, old_mode)


@contextmanager
def not_executable(path):
    old_mode = path.stat().st_mode
    path.chmod(0o644)
    try:
        yield
    finally:
        path.chmod(old_mode)


class FakeCmu:
    """The tweak, the shared library, stand-ins for the system programs and a firmware file, in a temporary folder."""

    def __init__(self, base):
        self.base = base
        self.bins = base / "bin"
        self.tmp = base / "tmp"
        self.tmp.mkdir()
        shutil.copytree(ROOT / "usb/lib", base / "usb/lib")
        self.tweak = base / "usb/tweaks/terminal"
        shutil.copytree(ROOT / "usb/tweaks/terminal", self.tweak)

        self.version = base / "version.ini"
        self.stock = base / "run-terminal.sh"
        write(self.version, 'JCI_SW_VER="MAZ_CMU-150_74.00.324"\n')
        write(self.stock, STOCK)

        # status looks for these programs; `lua` succeeds like a Lua that can load the posix module
        for name in ("terminal", "ivi-shell", "lua"):
            write(self.bins / name, SUCCEEDS, 0o755)
        write(self.bins / "busybox", BUSYBOX_WITH_SCRIPT, 0o755)

        # the tweak reads the firmware from the test's own file
        self.worker = self.tweak / "run.sh"
        write(self.worker, self.worker.read_text().replace("/jci/version.ini", shell_path(self.version)), 0o755)

        self.environment = dict(
            os.environ,
            PATH=shell_path(self.bins) + ":" + os.environ["PATH"],
            MZD_STOCK=shell_path(self.stock),
            MZD_IVI=shell_path(self.bins / "ivi-shell"),
            MZD_TERMINAL_BIN=shell_path(self.bins / "terminal"),
            MZD_TMP=shell_path(self.tmp),
        )

    def run(self, arguments, expected_code, expected_stdout=None, extra_environment=None, script=None):
        environment = dict(self.environment, **(extra_environment or {}))
        result = subprocess.run(
            [SHELL, shell_path(script or self.worker)] + arguments,
            capture_output=True,
            text=True,
            timeout=30,
            env=environment,
        )
        assert result.returncode == expected_code, (arguments, result.returncode, result.stdout, result.stderr)
        if expected_stdout is not None:
            assert result.stdout == expected_stdout, (arguments, result.stdout)
        return result

    def expect_unavailable(self, reason):
        """status says unavailable with a reason; Run refuses with the same reason."""
        result = self.run(["status"], 0, "unavailable\n")
        assert reason in result.stderr, (reason, result.stderr)
        result = self.run(["run"], 1, "")
        assert reason in result.stderr, (reason, result.stderr)

    def opener(self):
        """assets/terminal.sh, the script that run.sh calls."""
        return self.tweak / "assets/terminal.sh"

    def bridge(self):
        return self.tweak / "assets/mzd-kbd-bridge.lua"


def test_usage_and_arguments(cmu):
    cmu.run([], 0)
    cmu.run(["--help"], 0)
    cmu.run(["status", "extra"], 1, "")
    cmu.run(["install"], 1, "")
    cmu.run(["uninstall"], 1, "")
    assert cmu.run(["status"], 0, "uninstalled\n").stderr == ""


def test_status_unavailable(cmu):
    with replaced(cmu.version, 'JCI_SW_VER="MAZ_CMU-150_99.00.000"\n', 0o644):
        cmu.expect_unavailable("Requires firmware")

    with moved_away(cmu.stock):
        cmu.expect_unavailable("stock Terminal script is missing")

    with replaced(cmu.stock, STOCK.replace("export SHELL='/bin/sh'", "export SHELL='/bin/bash'"), 0o644):
        cmu.expect_unavailable("not the expected one")

    with not_executable(cmu.bins / "terminal"):
        cmu.expect_unavailable("Missing system program")

    with replaced(cmu.bins / "lua", FAILS):
        cmu.expect_unavailable("Lua interpreter")

    with replaced(cmu.bins / "busybox", BUSYBOX_WITHOUT_SCRIPT):
        cmu.expect_unavailable("script")

    with moved_away(cmu.bridge()):
        cmu.expect_unavailable("Missing tweak file")

    # An unreadable firmware file is a failed inspection, not "unavailable"
    with moved_away(cmu.version):
        cmu.run(["status"], 1, "")
        cmu.run(["run"], 1, "")


def test_run_environment_and_exit_codes(cmu):
    """Run with terminal.sh replaced by a stub that records how it was called and exits with the code we choose."""
    record = cmu.base / "record"

    def stub_opener(exit_code):
        write(
            cmu.opener(),
            "#!/bin/sh\n"
            '{ echo "args: $*"; echo "surface: $MZD_SURFACE"; echo "return: $MZD_RETURN_SURFACE"; '
            'echo "ivi: ${WAYLAND_IVI_SURFACE_ID-unset}"; echo "opera: ${OPERA_HOME-unset}"; } > '
            + shlex.quote(shell_path(record))
            + "\nexit "
            + str(exit_code)
            + "\n",
        )

    # The launcher's variables do not reach the Terminal, which returns to the launcher's surface
    stub_opener(0)
    cmu.run(["run"], 0, "Terminal closed.\n", LAUNCHER_ENVIRONMENT)
    assert record.read_text().splitlines() == [
        "args: --wait --hold --hint To exit: type exit + ENTER|or press HOME on controller",
        "surface: JCI_OPERA_SECONDARY",
        "return: 10",
        "ivi: unset",
        "opera: unset",
    ]

    # Both can be set from outside
    cmu.run(
        ["run"],
        0,
        "Terminal closed.\n",
        dict(LAUNCHER_ENVIRONMENT, MZD_SURFACE="JCI_OPERA_PRIMARY", MZD_RETURN_SURFACE=""),
    )
    assert "surface: JCI_OPERA_PRIMARY" in record.read_text()
    assert "return: \n" in record.read_text() + "\n"

    # Any failure of terminal.sh is code 1 with a message: code 2 would lock the launcher
    failures = [(1, "time limit"), (2, "could not be opened"), (3, "already open"), (4, "could not be restored"), (7, "could not be opened")]
    for opener_code, message in failures:
        stub_opener(opener_code)
        result = cmu.run(["run"], 1, "")
        assert message in result.stderr, (opener_code, result.stderr)


def test_terminal_sh_refuses(cmu):
    """The real terminal.sh opens nothing (code 2) and leaves no files when something is missing. The bridge is a stub,
    so the CMU's Lua is not needed to get as far as the checks."""
    write(cmu.bridge(), STUB_BRIDGE, 0o755)

    with replaced(cmu.stock, STOCK.replace("export SHELL='/bin/sh'", "export SHELL='/bin/bash'"), 0o644):
        cmu.run([], 2, None, None, cmu.opener())

    with not_executable(cmu.bins / "terminal"):
        cmu.run([], 2, None, None, cmu.opener())

    with moved_away(cmu.bridge()):
        cmu.run(["--wait"], 2, None, None, cmu.opener())

    assert not any(cmu.tmp.iterdir()), list(cmu.tmp.iterdir())


def test_terminal_sh_patches_stock_script(cmu):
    """The patched copy of the stock script: font and shell always, the transparency only if TERMINAL_ALPHA is set in
    the file. No Terminal appears (a stand-in cannot be a process named terminal on every system), so each run ends
    after its wait for the Terminal, shortened here to 1 s, with code 2; the patched copy is saved next to the log."""

    def start(name, alpha):
        folder = cmu.base / name
        folder.mkdir()
        text = cmu.opener().read_text()
        text = re.sub(r"^TERMINAL_OPEN_WAIT=\d+", "TERMINAL_OPEN_WAIT=1", text, count=1, flags=re.M)
        if alpha:
            text = re.sub(r"^TERMINAL_ALPHA=.*$", "TERMINAL_ALPHA=" + alpha, text, count=1, flags=re.M)
        write(folder / "terminal.sh", text, 0o755)
        write(folder / "mzd-kbd-bridge.lua", STUB_BRIDGE, 0o755)
        write(folder / "posixcompat.lua", "")

        own_tmp = cmu.base / (name + "-tmp")
        own_tmp.mkdir()
        process = subprocess.Popen(
            [SHELL, shell_path(folder / "terminal.sh"), "--log", shell_path(folder / "log")],
            env=dict(cmu.environment, MZD_TMP=shell_path(own_tmp)),
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
        )
        return process, folder, own_tmp

    runs = {"stock-alpha": start("stock-alpha", ""), "own-alpha": start("own-alpha", "150")}
    patched = {}
    for name, (process, folder, own_tmp) in runs.items():
        process.communicate(timeout=60)
        assert process.returncode == 2, (name, process.returncode)
        assert not any(own_tmp.iterdir()), list(own_tmp.iterdir())
        patched[name] = (folder / "patched-run-terminal.sh").read_text()

        # always: the font size, and the bridge as the Terminal's shell
        font_line = "{ echo '[terminal]'; echo 'font-size=20'; } > /tmp/root/weston.ini"
        shell_line = "export SHELL='" + shell_path(own_tmp) + "/mzd-kbd-bridge'"
        assert font_line in patched[name], patched[name]
        assert shell_line in patched[name], patched[name]

    assert 'ivi-shell -a "Wayland Terminal":255 > /dev/null &' in patched["stock-alpha"]
    assert 'ivi-shell -a "Wayland Terminal":150 > /dev/null &' in patched["own-alpha"]


def test_terminal_sh_recovers_from_a_failed_hook(cmu):
    """The Terminal is gone and the janitor never ran the hook (the bridge is a stub, so nobody does): terminal.sh waits a
    grace period and runs the hook itself. Failed screen or focus calls are tried again and, if they never work, end with
    code 4 instead of a success. A stub `ls` makes the Terminal "run" while a marker file exists; the test removes it."""
    write(cmu.bins / "ls", '#!/bin/sh\n[ -f "$TEST_TERMINAL_UP" ] && echo "lrwxrwxrwx 1 root root 0 Jan 1 00:00 /proc/1/exe -> /usr/bin/terminal"\nexit 0\n', 0o755)
    # fails the first TEST_FAILS calls (counted in a file), then works; TEST_FAILS=all never works
    counted_failure = (
        "#!/bin/sh\n"
        '[ "$TEST_FAILS" = all ] && exit 1\n'
        'count=$(cat "$TEST_COUNT" 2>/dev/null || echo 0); echo $((count + 1)) > "$TEST_COUNT"\n'
        '[ "$count" -lt "${TEST_FAILS:-0}" ] && exit 1\n'
        "exit 0\n"
    )
    write(cmu.bins / "ivi-shell", counted_failure, 0o755)
    write(cmu.bins / "dbus-send", counted_failure.replace("TEST_COUNT", "TEST_DBUS_COUNT").replace("TEST_FAILS", "TEST_DBUS_FAILS"), 0o755)
    write(cmu.bridge(), STUB_BRIDGE, 0o755)
    write(cmu.tweak / "assets/posixcompat.lua", "")

    text = cmu.opener().read_text()
    text = re.sub(r"^HOOK_GRACE=\d+", "HOOK_GRACE=2", text, count=1, flags=re.M)
    own_opener = cmu.tweak / "assets/terminal-short.sh"
    write(own_opener, text, 0o755)

    def start(name, ivi_fails, dbus_fails):
        folder = cmu.base / name
        folder.mkdir()
        own_tmp = cmu.base / (name + "-tmp")
        own_tmp.mkdir()
        up = folder / "terminal-up"
        up.write_text("")
        process = subprocess.Popen(
            [SHELL, shell_path(own_opener), "--wait", "--log", shell_path(folder / "log")],
            env=dict(
                cmu.environment,
                MZD_TMP=shell_path(own_tmp),
                MZD_DBUS_SEND=shell_path(cmu.bins / "dbus-send"),
                MZD_RETURN_SURFACE="10",
                TEST_TERMINAL_UP=shell_path(up),
                TEST_COUNT=shell_path(folder / "ivi-count"),
                TEST_DBUS_COUNT=shell_path(folder / "dbus-count"),
                TEST_FAILS=ivi_fails,
                TEST_DBUS_FAILS=dbus_fails,
            ),
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
        )
        return process, folder, up, own_tmp

    # name: (failing ivi-shell calls, the stock script makes the first one; expected exit code; text expected in the log)
    cases = {
        "all-works": ("0", 0, "the hook did not run in 2 s"),
        "focus-works-on-retry": ("3", 0, "focus rc=0 (try 2)"),
        "focus-never-works": ("all", 4, "was not returned"),
    }
    runs = {name: start(name, fails, "0") + (code, expected) for name, (fails, code, expected) in cases.items()}
    # a surface request that never works: the stub dbus-send is replaced by one that fails
    runs["surface-never-works"] = start("surface-never-works", "0", "all") + (4, "surface rc=1 (try 3)")

    for name, (process, folder, up, own_tmp, code, expected) in runs.items():
        for _ in range(100):
            if (folder / "log").exists() and "terminal: open" in (folder / "log").read_text():
                break
            time.sleep(0.1)
        up.unlink()
        process.communicate(timeout=60)
        log = (folder / "log").read_text()
        assert process.returncode == code, (name, process.returncode, log)
        assert expected in log, (name, log)
        assert "running it here" in log, (name, log)
        assert not any(own_tmp.iterdir()), (name, list(own_tmp.iterdir()))


TESTS = [
    test_usage_and_arguments,
    test_status_unavailable,
    test_run_environment_and_exit_codes,
    test_terminal_sh_refuses,
    test_terminal_sh_patches_stock_script,
    test_terminal_sh_recovers_from_a_failed_hook,
]

for test in TESTS:
    with tempfile.TemporaryDirectory(prefix="cmu-terminal-") as directory:
        test(FakeCmu(Path(directory)))

print(
    "TERMINAL_CONTRACT_PASSED: %d groups: usage, status, refusals, environment and exit codes, patched stock script, failed hook."
    % len(TESTS)
)
