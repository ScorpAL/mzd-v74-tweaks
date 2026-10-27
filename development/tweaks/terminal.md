# Terminal

System command for firmware 74.00.324. Select **Run** in the launcher, or invoke `sh run.sh run`.

## The problem

The CMU has a Terminal (`/jci/scripts/run-terminal.sh`), but with a USB keyboard it is hardly usable and it leaves the CMU
in a bad state:

- **Keys get lost.** The CMU filters the USB keyboard and drops a key that is pressed while another one is held. Shift+key,
  Ctrl+key (Ctrl+C) and fast typing do not work.
- **The CMU reacts to the typing.** Its own screens read the keyboard too, so letters typed in the Terminal open and change
  CMU screens behind it.
- **The multicontroller dies.** The stock script gives the keyboard focus to the Terminal and never takes it back, so after
  the Terminal is closed the multicontroller stays dead until a reboot.
- **The font is tiny.** The stock Terminal is hard to read on the small CMU screen.
- **It does not fit the launcher.** The launcher is a second Opera. The Terminal must not inherit its environment, and the
  launcher's screen and focus must come back afterwards.

## The solution

The stock file is never changed. A copy is patched in memory and the pieces below fix the problems. In the order they run:

1. **The launcher** starts `run.sh run` as a background job (`progress=true`), so Exit stays disabled while the Terminal is open.
2. **`run.sh`** checks that this CMU can run the Terminal, removes the launcher's own environment, says where the focus goes
   back (the launcher) and starts `assets/terminal.sh`, with a hint on how to leave. Whatever happens, it reports
   an ordinary failure (exit code 1): code 2 is critical for the launcher and would block it.
3. **`assets/terminal.sh`** copies the bridge to RAM, patches the stock script in memory (a larger font, which fixes the tiny
   text, and the bridge as the Terminal's shell) and runs it. Then it waits until the Terminal is closed.
4. **The stock script** opens the Terminal window. The Terminal starts its shell, which is now the bridge.
5. **`assets/mzd-kbd-bridge.lua`** (with `posixcompat.lua`) is the shell. It reads the USB keyboard directly, so no key is lost,
   and feeds a real shell on a pseudo-terminal. It also keeps one key pressed on the multicontroller's virtual keyboard (see
   "The held key"), so the CMU ignores the USB keyboard. HOME on the multicontroller closes it.
6. **The janitor**, a small process started by the bridge, notices when the Terminal is gone, however it ended, and runs the
   **hook** that `terminal.sh` wrote: the hook shows the launcher's screen again and gives it the keyboard focus. `terminal.sh`
   sees the hook's result, cleans up and exits, `run.sh` prints "Terminal closed." and the launcher shows the result.

## The held key

The `devices` service of the CMU keeps one global held key: while a key is down, the keys, touch and mouse motion of every
other input device are dropped, and a key that is never released is let go after 30 s. With `--hold` the bridge presses F24
on the multicontroller's "Virtual Keyboard" (one event written to `/dev/input/event1`) and renews it every 5 s, so the CMU
does not see the USB keyboard. HOME and the knob come from the same device and still pass.

The service drops a press made while a USB key is down, so the bridge does not write then and tries again after the release.
The key is held from start to end, with or without a keyboard. If the bridge dies, the service releases the key within 30 s.

## What `status` checks

Read only; `uninstalled` means ready (displayed as Ready), otherwise `unavailable` with a reason on stderr. It checks the
firmware line in `/jci/version.ini`, the tweak's own files, that the stock script still contains the two lines `terminal.sh`
replaces, that `terminal` and `ivi-shell` are executable, that `lua` can load `posix`, and that BusyBox has the `script` applet.

## What is written

RAM only: the bridge and `posixcompat.lua` in `/tmp`, the rc, hook, flag and result files, the lock `/tmp/mzd-terminal.lock`,
`/tmp/mzd-kbd-lua-<pid>.rc`, and what the stock script writes (`/tmp/root/weston.ini`, `modprobe usbhid`). The F24 event is not
persistent. Nothing is written to the USB drive or to the flash. Everything the tweak created is removed when the Terminal is
closed.

## terminal.sh options

The tweak uses `--wait --hold --hint` (the hint on how to leave, printed first in the Terminal) and the variables
`MZD_SURFACE=JCI_OPERA_SECONDARY` and `MZD_RETURN_SURFACE=10` (the launcher's screen). The rest is for debugging:
`--timeout N` closes the Terminal after N seconds (default: no limit), `--rc FILE` runs commands first in the Terminal,
`--bridge FILE` uses another bridge, `--log FILE` writes a line per step (the bridge log goes next to it), and
`TERMINAL_ALPHA` in the file sets the window transparency (default: the stock value). The bridge reads `MZD_KBD_*`
variables, see its header. `MZD_TMP`, `MZD_STOCK`, `MZD_IVI`, `MZD_TERMINAL_BIN`, `MZD_DBUS_SEND` and `MZD_HMI_BUS` replace
system paths in tests.

## Limits and tests

US layout only. The pty size is copied once at the start. Touch is disabled while the Terminal is open. HOME is handled by the
bridge, so a hung bridge is not closed by HOME.

`tests/contract/test_terminal.py` covers `run.sh` (status, refusals, environment, exit codes) and what `terminal.sh` refuses
or patches, with stub programs. The bridge, the pty, the Terminal window and the return of the focus and of the launcher's
screen need a vehicle.
