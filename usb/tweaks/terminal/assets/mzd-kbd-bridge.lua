#!/usr/bin/lua

-- mzd-kbd-bridge.lua - the shell of the CMU Terminal when a USB keyboard is used (no compiled program).
--
-- The CMU filters the USB keyboard before the Terminal sees it (no Shift+key, Ctrl+key or fast typing). The bridge reads the
-- RAW keyboard (/dev/input/eventN), translates the keys itself (US layout) and feeds a real shell. The stock Terminal script
-- starts the bridge as the Terminal's shell (SHELL=/tmp/mzd-kbd-bridge) and the Terminal shows what it prints.
--   * the pty comes from BusyBox: busybox script -q -f -c "<shell>" /dev/null (the CMU's Lua has no pty calls);
--   * what the Terminal itself sends on stdin is ignored (--stdin=forward passes it on: tests, paste);
--   * the window size is copied once at the start (stty size); later resizing is not followed;
--   * keyboards are found by name and by their key bits, also when plugged in later (see scan_devices);
--   * --hold-key makes the CMU ignore the USB keyboard (see "the held key");
--   * a detached helper stops the shell if the bridge dies and, with --on-exit, runs a command when the Terminal is gone.
-- It ends when HOME is pressed on the multicontroller, the shell exits, the Terminal is closed or --max-seconds has passed (no
-- limit by default). Exit code: the shell's, 0 after HOME, 254 time limit, 255 no start. With --result-file the reason is
-- written to the file: home, shell-exit N, time-limit, terminated or terminal-closed.
--
-- The file is read top to bottom: settings (options and MZD_KBD_* variables), the US layout and key translation, devices and
-- their search, the held key, the helper process, then the session: handle_key, the three pump_* functions, and start_shell,
-- run_loop and leave, which main runs in this order.
local script_dir = (arg and arg[0] or ""):match("^(.*)/") or "."

-- posixcompat.lua lies next to this file
package.path = script_dir .. "/?.lua;" .. package.path
local sys = require("posixcompat")
local posix = sys.raw

local VERSION = "mzd-kbd-bridge 0.1.0 (lua)"

local config = {
    shell = "/bin/sh",
    log = nil,
    fake_keyboards = {},
    exitdev = nil,
    max_seconds = 0,
    verbose = false,
    scan = true,
    on_exit = nil,
    result = nil,
    watch_pid = 0,
    stdin = "ignore",
}

-- Options given as --name=value, and flags; each one changes the settings
local VALUE_OPTIONS = {
    ["--exec"] = function(value)
        config.shell = value
    end,
    ["--log"] = function(value)
        config.log = value
    end,
    ["--raw"] = function(value)
        config.fake_keyboards[#config.fake_keyboards + 1] = value
    end,
    ["--exit-dev"] = function(value)
        config.exitdev = value
    end,
    ["--max-seconds"] = function(value)
        config.max_seconds = tonumber(value) or config.max_seconds
    end,
    ["--on-exit"] = function(value)
        config.on_exit = value
    end,
    ["--result-file"] = function(value)
        config.result = value
    end,
    ["--watch-pid"] = function(value)
        config.watch_pid = tonumber(value) or 0
    end,
    ["--stdin"] = function(value)
        config.stdin = value
    end,
    ["--hold-key"] = function(value)
        config.hold = tonumber(value)
    end,
}
local FLAG_OPTIONS = {
    ["--no-scan"] = function()
        config.scan = false
    end,
    ["-v"] = function()
        config.verbose = true
    end,
}

local USAGE = table.concat({
    "mzd-kbd-bridge [--exec=SHELL] [--log=FILE] [-v] [--max-seconds=N] [--on-exit=CMD] [--result-file=FILE]",
    "               [--raw=DEV]... [--exit-dev=DEV] [--no-scan] [--watch-pid=N] [--stdin=ignore|forward]",
    "               [--hold-key=CODE] [--version]",
    "Runs SHELL on a pty (busybox script); keys come from the raw USB keyboard (US layout). Home on the commander closes it.",
    "Environment (the Terminal starts us without arguments): MZD_KBD_LOG, MZD_KBD_VERBOSE, MZD_KBD_ON_EXIT,",
    "MZD_KBD_RESULT_FILE, MZD_KBD_MAX_SECONDS, MZD_KBD_STDIN, MZD_KBD_EXIT_DEV, MZD_KBD_RAW (a:b), MZD_KBD_NO_SCAN,",
    "MZD_KBD_SPY, MZD_KBD_HOLD.",
    "Lua only: MZD_BUSYBOX (default /bin/busybox), MZD_SCRIPT_SHELL (the shell that runs the command line, default /bin/sh).",
}, "\n")

for _, argument in ipairs(arg) do
    local name, value = argument:match("^(%-%-[%w%-]+)=(.*)$")
    if argument == "--version" then
        print(VERSION)
        os.exit(0)
    elseif argument == "--help" then
        print(USAGE)
        os.exit(0)
    elseif name and VALUE_OPTIONS[name] then
        VALUE_OPTIONS[name](value)
    elseif FLAG_OPTIONS[argument] then
        FLAG_OPTIONS[argument]()
    end
end

local function env(name)
    local v = os.getenv(name)
    if v and v ~= "" then
        return v
    end
end

config.log = config.log or env("MZD_KBD_LOG")
if env("MZD_KBD_VERBOSE") then
    config.verbose = true
end

config.on_exit = config.on_exit or env("MZD_KBD_ON_EXIT")
config.result = config.result or env("MZD_KBD_RESULT_FILE")
if env("MZD_KBD_MAX_SECONDS") and tonumber(env("MZD_KBD_MAX_SECONDS")) > 0 then
    config.max_seconds = tonumber(env("MZD_KBD_MAX_SECONDS"))
end

if env("MZD_KBD_STDIN") then
    config.stdin = env("MZD_KBD_STDIN")
end

-- The Terminal starts the bridge without arguments, so every setting can also come from the environment (MZD_KBD_*).
-- RAW, EXIT_DEV and NO_SCAN replace the device search with fake devices (tests).
if env("MZD_KBD_EXIT_DEV") then
    config.exitdev = env("MZD_KBD_EXIT_DEV")
end

if env("MZD_KBD_RAW") then
    for p in env("MZD_KBD_RAW"):gmatch("[^:]+") do
        config.fake_keyboards[#config.fake_keyboards + 1] = p
    end
end

if env("MZD_KBD_NO_SCAN") then
    config.scan = false
end

if env("MZD_KBD_HOLD") then
    config.hold = tonumber(env("MZD_KBD_HOLD"))
end

config.spy = env("MZD_KBD_SPY") ~= nil -- diagnostics: also read the CMU's FILTERED keyboard and log its keys (shows what reaches the CMU screen)

local logf = config.log and io.open(config.log, "a")
local function log(fmt, ...)
    if not logf then
        return
    end

    logf:write(string.format("[%.3f] ", sys.uptime()), string.format(fmt, ...), "\n")
    logf:flush()
end

-- ---------------------------------------------------------------- US layout
-- NORMAL and SHIFTED: Linux key code -> the character without and with Shift
local NORMAL, SHIFTED = {}, {}
do
    local n1, s1 = "1234567890-=", "!@#$%^&*()_+"
    for i = 1, 12 do
        NORMAL[1 + i] = n1:sub(i, i)
        SHIFTED[1 + i] = s1:sub(i, i)
    end

    local function row(first, letters)
        for i = 1, #letters do
            local c = letters:sub(i, i)
            NORMAL[first + i - 1] = c
            SHIFTED[first + i - 1] = c:upper()
        end
    end

    row(16, "qwertyuiop")
    row(30, "asdfghjkl")
    row(44, "zxcvbnm")
    local function pair(code, n, s)
        NORMAL[code] = n
        SHIFTED[code] = s
    end

    pair(26, "[", "{")
    pair(27, "]", "}")
    pair(39, ";", ":")
    pair(40, "'", '"')
    pair(41, "`", "~")
    pair(43, "\\", "|")
    pair(51, ",", "<")
    pair(52, ".", ">")
    pair(53, "/", "?")
    pair(86, "<", ">") -- 86: the extra key of ISO keyboards
    pair(57, " ", " ")
    pair(28, "\r", "\r")
    pair(15, "\t", "\t")
    pair(14, "\127", "\127")
    pair(1, "\27", "\27")
    local kp = "789-456+1230." -- keypad, Num Lock assumed on
    for i = 1, #kp do
        pair(70 + i, kp:sub(i, i), kp:sub(i, i))
    end

    pair(55, "*", "*")
    pair(96, "\r", "\r")
    pair(98, "/", "/")
end

local NAV = {
    [103] = "\27[A",
    [108] = "\27[B",
    [106] = "\27[C",
    [105] = "\27[D",
    [102] = "\27[H",
    [107] = "\27[F",
    [110] = "\27[2~",
    [111] = "\27[3~",
    [104] = "\27[5~",
    [109] = "\27[6~",
    [59] = "\27OP",
    [60] = "\27OQ",
    [61] = "\27OR",
    [62] = "\27OS",
    [63] = "\27[15~",
    [64] = "\27[17~",
    [65] = "\27[18~",
    [66] = "\27[19~",
    [67] = "\27[20~",
    [68] = "\27[21~",
    [87] = "\27[23~",
    [88] = "\27[24~",
}

local KEY_LCTRL, KEY_LSHIFT, KEY_RSHIFT, KEY_LALT, KEY_CAPS, KEY_RCTRL, KEY_RALT, KEY_HOME =
    29, 42, 54, 56, 58, 97, 100, 102
local mods = { lshift = false, rshift = false, lctrl = false, rctrl = false, lalt = false, ralt = false, caps = false }

-- The modifier keys that are held down, and the field of `mods` each one sets (Caps Lock toggles and is handled apart)
local MODIFIER_FIELDS = {
    [KEY_LSHIFT] = "lshift",
    [KEY_RSHIFT] = "rshift",
    [KEY_LCTRL] = "lctrl",
    [KEY_RCTRL] = "rctrl",
    [KEY_LALT] = "lalt",
    [KEY_RALT] = "ralt",
}

-- one key press (or repeat) -> the bytes for the shell, or nil
local function translate(code)
    local shift, ctrl, alt = mods.lshift or mods.rshift, mods.lctrl or mods.rctrl, mods.lalt or mods.ralt
    local seq = NAV[code]
    if seq then
        return (alt and "\27" or "") .. seq
    end

    local c = NORMAL[code]
    if not c then
        return nil
    end

    local letter = c:match("^%l$") ~= nil

    -- Shift+Tab
    if code == 15 and shift then
        return "\27[Z"
    end

    local use_shift = shift

    -- Caps Lock changes letters only
    if letter then
        use_shift = (shift and not mods.caps) or (not shift and mods.caps)
    end

    local o = use_shift and SHIFTED[code] or c
    if ctrl then
        if letter then
            o = string.char(c:byte() % 32)
        elseif c == "[" then
            o = "\27"
        elseif c == "\\" then
            o = "\28"
        elseif c == "]" then
            o = "\29"
        elseif c == " " or c == "2" then
            o = "\0"
        elseif c == "/" or c == "-" then
            o = "\31"
        elseif c == "6" then
            o = "\30"
        elseif c == "8" then
            o = "\127"
        end
    end
    return (alt and "\27" or "") .. o
end

-- ---------------------------------------------------------------- small helpers
local function write_all(fd, s)
    local off = 0
    while off < #s do
        local n = posix.write(fd, s:sub(off + 1))
        if not n then
            return false
        end

        off = off + n
    end
    return true
end

local function shquote(s)
    return "'" .. s:gsub("'", "'\\''") .. "'"
end

local function sh_out(cmd)
    local f = io.popen(cmd .. " 2>/dev/null")
    if not f then
        return ""
    end

    local s = f:read("*a") or ""
    f:close()
    return (s:gsub("%s+$", ""))
end

-- ---------------------------------------------------------------- devices
local leaving = false

-- What a device is (the role field of its record). The multicontroller is the "Virtual Keyboard": HOME on it closes the
-- bridge and the held key is written to it. The spy is the CMU's filtered keyboard, read only with MZD_KBD_SPY. The log shows
-- the numbers.
local ROLE_USB_KEYBOARD, ROLE_MULTICONTROLLER, ROLE_SPY = 0, 1, 3

-- One record per open input device: fd, path, role, buf (bytes not yet parsed) and down (USB keyboards: key code -> time it
-- went down).
local devices = {}
local function is_open(path)
    for _, device in ipairs(devices) do
        if device.path == path then
            return true
        end
    end
    return false
end

local function add_dev(path, role, fd)
    devices[#devices + 1] = { fd = fd, path = path, role = role, buf = "", down = {} }
    log("open %s role=%d", path, role)
end

local function drop_dev(i)
    local device = devices[i]
    sys.close(device.fd)
    log("closed %s", device.path)
    table.remove(devices, i)
end

local function read_file(path)
    local f = io.open(path, "r")
    if not f then
        return nil
    end

    local s = f:read("*a")
    f:close()
    return s
end

-- do the key bits of /sys/class/input/eventN/device/capabilities/key contain A, left Shift, Space and Enter? nil = cannot tell
local function has_keyboard_keys(n)
    local s = read_file("/sys/class/input/event" .. n .. "/device/capabilities/key")
    if not s then
        return nil
    end

    local words = {}
    for w in s:gmatch("%x+") do
        words[#words + 1] = w
    end

    local function bit(k)
        local w = words[#words - math.floor(k / 32)]
        if not w then
            return false
        end
        return math.floor(tonumber(w, 16) / 2 ^ (k % 32)) % 2 == 1
    end
    return bit(30) and bit(42) and bit(57) and bit(28)
end

-- Runs once a second: a USB keyboard can be plugged in or pulled out at any time (a pulled one is dropped when reading fails).
-- "Virtual Keyboard" is the multicontroller, "filtered-*" and "Virtual*" are devices of the CMU itself; any other device that has
-- the keys of a keyboard is a USB keyboard.
local function scan_devices()
    for _, p in ipairs(config.fake_keyboards) do
        if not is_open(p) then
            local fd = sys.open_nonblock(p, true)
            if fd then
                add_dev(p, ROLE_USB_KEYBOARD, fd)
            end
        end
    end

    if config.exitdev and not is_open(config.exitdev) then
        local fd = sys.open_nonblock(config.exitdev, false)
        if fd then
            add_dev(config.exitdev, ROLE_MULTICONTROLLER, fd)
            config.hold_path = config.hold_path or config.exitdev
        end
    end

    if not config.scan then
        return
    end

    for i = 0, 31 do
        local path = "/dev/input/event" .. i
        if not is_open(path) then
            local name = read_file("/sys/class/input/event" .. i .. "/device/name")
            if name then
                name = name:gsub("%s+$", "")
                if name == "Virtual Keyboard" then
                    local fd = sys.open_nonblock(path, false)
                    if fd then
                        add_dev(path, ROLE_MULTICONTROLLER, fd)
                    end

                    config.hold_path = config.hold_path or path
                elseif name:match("^filtered%-keyboard") then
                    if config.spy then
                        local fd = sys.open_nonblock(path, false)
                        if fd then
                            add_dev(path, ROLE_SPY, fd)
                        end
                    end
                elseif not (name:match("^filtered%-") or name:match("^Virtual")) and has_keyboard_keys(i) then
                    local fd = sys.open_nonblock(path, true)
                    if fd then
                        log("keyboard: %s (%s)", path, name)
                        add_dev(path, ROLE_USB_KEYBOARD, fd)
                    end
                end
            end
        end
    end
end

-- ---------------------------------------------------------------- the held key (no program, no ioctl)
-- The `devices` service of the CMU keeps ONE global "held key": while a key is down, the keys of every OTHER input device (and
-- their touch / mouse motion) are dropped. A key that is never released is let go by the service after 30 s ("Stuck key", setting
-- composite/timeout). The bridge presses one harmless key (config.hold, F24) on the multicontroller's virtual keyboard with a plain
-- write() of two input_event structures to its node, and presses it again every HOLD_RENEW seconds. While it is held, the USB
-- keyboard does not reach the filtered keyboard (event3) that the CMU user interface reads; the bridge reads the raw keyboard
-- itself. The multicontroller's own keys (HOME, knob) come from the same device and still pass. The key is released when the
-- bridge leaves; if the bridge dies, the service releases it by itself within 30 s.
-- It is held from start to end, also without a USB keyboard, so a keyboard plugged in later is blocked from its first key.
-- The service silently drops a press while a key of another device is down. So nothing is written while a USB key is down
-- (usb_key_is_down); it is written as soon as all keys are up (the main loop calls update_hold on every pass).
local HOLD_RENEW = 5
local hold_fd, hold_since, hold_down = nil, 0, false

-- A key event followed by SYN_REPORT, in the 16-byte input_event layout of the CMU: 8 bytes of time, type, code, value.
local function key_event(code, value)
    local function le16(n)
        return string.char(n % 256, math.floor(n / 256) % 256)
    end

    local function le32(n)
        return string.char(
            n % 256,
            math.floor(n / 256) % 256,
            math.floor(n / 65536) % 256,
            math.floor(n / 16777216) % 256
        )
    end
    return string.rep("\0", 8)
        .. le16(1)
        .. le16(code)
        .. le32(value)
        .. string.rep("\0", 8)
        .. le16(0)
        .. le16(0)
        .. le32(0)
end

local function hold_release(why)
    if hold_fd and hold_down then
        posix.write(hold_fd, key_event(config.hold, 0))
        hold_down = false
        log("released the held key %d (%s)", config.hold, why)
    end
end

local function usb_key_is_down() -- a key "down" for more than 20 s is a lost release or a stuck key: not waited for
    local now = sys.uptime()
    for _, device in ipairs(devices) do
        if device.role == ROLE_USB_KEYBOARD then
            for _, since in pairs(device.down) do
                if now - since < 20 then
                    return true
                end
            end
        end
    end
    return false
end

local function update_hold()
    if not config.hold or leaving then
        return
    end

    if not hold_fd then
        -- the multicontroller's device is not found (yet)
        if not config.hold_path then
            return
        end

        hold_fd = sys.open_nonblock(config.hold_path, true)
        if not hold_fd then
            log("CANNOT open %s for writing", config.hold_path)
            config.hold = nil
            return
        end
    end

    if hold_down and sys.uptime() - hold_since < HOLD_RENEW then
        return
    end

    -- the service would drop the press: try again after the release
    if usb_key_is_down() then
        return
    end

    if not hold_down then
        posix.write(hold_fd, key_event(config.hold, 1))
        hold_down = true
        log("holding key %d on %s", config.hold, config.hold_path)
    else
        posix.write(hold_fd, key_event(config.hold, 0) .. key_event(config.hold, 1)) -- release + press: a new 30 s
        if config.verbose then
            log("held key %d renewed", config.hold)
        end
    end

    hold_since = sys.uptime()
end

local function set_caps_led(on)
    local ev = string.char(0, 0, 0, 0, 0, 0, 0, 0, 17, 0, 1, 0, on and 1 or 0, 0, 0, 0) -- EV_LED (17), LED_CAPSL (1)
    for _, device in ipairs(devices) do
        if device.role == ROLE_USB_KEYBOARD then
            posix.write(device.fd, ev)
        end
    end
end

-- ---------------------------------------------------------------- the helper: reaper and janitor
-- A detached process, started always. REAPER: the shell lives on a pty held by `busybox script`; if the bridge dies (kill -9, a
-- crash) nothing closes that pty, so the helper stops the session. JANITOR (only with --on-exit): when the Terminal (the parent of the
-- bridge, or --watch-pid) is gone, whatever the way, it runs the command with `sh -c` (give the keyboard focus back, a flag file...).
local function start_helper(watch, shell_pid, bridge_pid, rc_path)
    local janitor = config.on_exit ~= nil
    local p = sys.fork()
    if not p then
        if janitor then
            log("janitor: fork failed")
        end
        return
    end

    -- the first child ends at once: the helper is its child
    if p > 0 then
        sys.wait(p, 0)
        return
    end

    local g = sys.fork()
    if g and g > 0 then
        sys._exit(0)
    end

    sys.setpid("s")
    sys.signal(posix.SIGHUP, "SIG_IGN")

    -- nothing inherited: the pipes and devices must not stay open
    for fd = 3, 255 do
        sys.close(fd)
    end

    local nul = sys.open_nonblock("/dev/null", true)
    if nul then
        sys.dup2(nul, 0)
        sys.dup2(nul, 1)
        sys.dup2(nul, 2)
    end

    logf = config.log and io.open(config.log, "a")
    local limit = config.max_seconds > 0 and config.max_seconds + 120 or math.huge -- no time limit by default
    if janitor then
        log("janitor: watching pid %d (limit %d s)", watch, limit)
    end

    local reaped = false
    local function reap_shell()
        if reaped then
            return
        end

        reaped = true
        if not sys.pid_gone(shell_pid) then
            log(
                "%s: the bridge (pid %d) is gone, stopping the shell session (pid %d)",
                janitor and "janitor" or "reaper",
                bridge_pid,
                shell_pid
            )
            sys.kill(shell_pid, posix.SIGHUP)
            sys.sleep_ms(300)
            if not sys.pid_gone(shell_pid) then
                sys.kill(shell_pid, posix.SIGKILL)
            end
        end

        os.remove(rc_path)
    end

    local t0 = sys.uptime()
    while sys.uptime() - t0 < limit do
        if not reaped and sys.pid_gone(bridge_pid) then
            reap_shell()
            if not janitor then
                break
            end
        end

        if janitor and sys.pid_gone(watch) then
            break
        end

        sys.sleep_ms(200)
    end

    reap_shell()
    if not janitor then
        sys._exit(0)
    end

    log("janitor: pid %d is gone, running: %s", watch, config.on_exit)
    local c = sys.fork()
    if c == 0 then
        if not env("XDG_RUNTIME_DIR") then
            sys.setenv("XDG_RUNTIME_DIR", "/tmp")
        end

        sys.exec("/bin/sh", "-c", config.on_exit)
        sys._exit(127)
    end

    if c and c > 0 then
        local ended, status = false, nil
        local t1 = sys.uptime()
        while not ended and sys.uptime() - t1 < 600 do
            local w, reason, st = sys.wait(c, posix.WNOHANG or 1)
            if w and w > 0 then
                ended = true
                status = reason == "exited" and st or 128 + (st or 0)
            else
                sys.sleep_ms(200)
            end
        end

        if ended then
            log("janitor: command ended with %d", status)
        else
            log("janitor: command did not end in 600 s, killed")
            sys.kill(c, posix.SIGKILL)
        end
    end

    log("janitor: done")
    sys._exit(0)
end

-- ---------------------------------------------------------------- session
-- State of the running session. start_shell sets most of it; the main loop ends when done is set, with the exit code and
-- the reason that leave reports.
local stdin_read, stdin_write, stdout_read, stdout_write -- the pipes of the shell's pty: its stdin, and its stdout and stderr
local shell_child, rcfile, saved_tty, deadline, last_scan
local got_term = false
local exit_code, reason, child_gone = 0, "terminal-closed", false
local done = false

-- One key event: value 1 press, 0 release, 2 auto-repeat (typed again like a press). Modifiers only change state; the other
-- keys are translated and written to the shell.
local function handle_key(device, code, value)
    if device.role == ROLE_SPY then
        log("filtered key %d value %d", code, value)
        return
    end

    if device.role == ROLE_MULTICONTROLLER then
        if code == KEY_HOME and value == 1 then
            log("Home on the commander: closing")
            reason = "home"
            done = true
        end
        return
    end

    local down, press = value ~= 0, value == 1

    -- for update_hold
    if value == 1 then
        device.down[code] = sys.uptime()
    elseif value == 0 then
        device.down[code] = nil
    end

    local modifier = MODIFIER_FIELDS[code]
    if config.verbose and (modifier or code == KEY_CAPS) then
        log("modifier %d value %d", code, value)
    end

    if modifier then
        mods[modifier] = down
        return
    end

    if code == KEY_CAPS then
        if press then
            mods.caps = not mods.caps
            set_caps_led(mods.caps)
        end
        return
    end

    if not down then
        return
    end

    local out = translate(code)
    if config.verbose then
        log("key %d value %d -> %d byte(s)", code, value, out and #out or 0)
    end

    if out then
        write_all(stdin_write, out)
    end
end

-- Hands every key event of a device to handle_key. An input_event is 16 bytes: time (8), type (2), code (2), value (4, signed).
local EVENT_SIZE = 16
local EV_KEY = 1
local function read_device_events(device)
    local data = posix.read(device.fd, EVENT_SIZE * 32)
    if not data or #data == 0 then
        return
    end

    device.buf = device.buf .. data
    while #device.buf >= EVENT_SIZE do
        local event_bytes = { device.buf:byte(1, EVENT_SIZE) }
        device.buf = device.buf:sub(EVENT_SIZE + 1)

        local event_type = event_bytes[9] + event_bytes[10] * 256
        if event_type == EV_KEY then
            local code = event_bytes[11] + event_bytes[12] * 256
            local value = event_bytes[13] + event_bytes[14] * 256 + event_bytes[15] * 65536 + event_bytes[16] * 16777216
            if value >= 2147483648 then
                value = value - 4294967296
            end

            handle_key(device, code, value)
            if done then
                break
            end
        end
    end
end

-- Waits up to 500 ms for the Terminal, the shell or a device; returns the poll table with the results.
local function wait_for_input()
    local fds = { [0] = { events = { IN = true } }, [stdout_read] = { events = { IN = true } } }
    for _, device in ipairs(devices) do
        fds[device.fd] = { events = { IN = true } }
    end

    sys.poll(fds, 500)
    return fds
end

-- The three pump functions handle one source each. The first two return false when the main loop has to end.

-- shell output -> Terminal
local function pump_shell_output(fds)
    local ready = fds[stdout_read].revents
    if ready and (ready.IN or ready.HUP or ready.ERR) then
        local data = posix.read(stdout_read, 4096)
        if data and #data > 0 then
            if not write_all(1, data) then
                return false
            end
        elseif data == "" then
            child_gone = true
        end
    end

    return true
end

-- what the Terminal sends us (its own keys, or a paste)
local function pump_terminal_input(fds)
    local ready = fds[0].revents
    if ready and ready.IN then
        local data = posix.read(0, 4096)
        if data == "" then
            log("terminal closed the input")
            return false
        end

        if data and #data > 0 and config.verbose then
            log("terminal stdin: %s", (data:sub(1, 40):gsub(".", function(c)
                return string.format("%02x ", c:byte())
            end)))
        end

        if data and config.stdin == "forward" then
            write_all(stdin_write, data)
        end
    elseif ready and (ready.HUP or ready.ERR) then
        log("terminal closed")
        return false
    end

    return true
end

-- input devices: new key events, or a device that has gone (a pulled USB keyboard)
local function pump_devices(fds)
    local i = 1
    while i <= #devices and not done do
        local device = devices[i]
        local device_ready = fds[device.fd] and fds[device.fd].revents
        local dropped = false
        if device_ready and device_ready.IN then
            read_device_events(device)
        elseif device_ready and (device_ready.HUP or device_ready.ERR or device_ready.NVAL) then
            drop_dev(i)
            dropped = true
        end

        if not dropped then
            i = i + 1
        end
    end
end

-- ---------------------------------------------------------------- start, main loop, leave
-- Starts the shell on a pty (busybox script) and the helper process, and finds the devices.
local function start_shell()
    local pid_self, pid_parent = sys.self_ids()
    log(
        "%s start shell=%s max=%d pid=%d parent=%d",
        VERSION,
        config.shell,
        config.max_seconds,
        pid_self or 0,
        pid_parent or 0
    )

    for _, name in ipairs({ "SIGTERM", "SIGHUP", "SIGINT" }) do
        sys.signal(posix[name], function()
            got_term = true
        end)
    end

    sys.signal(posix.SIGPIPE, "SIG_IGN")

    -- The shell's exit code reaches the bridge through this file: it is written by the last command of the line given to `script`.
    rcfile = string.format("/tmp/mzd-kbd-lua-%d.rc", pid_self or 0)
    os.remove(rcfile)
    local rows, cols = sh_out("stty size"):match("^(%d+) (%d+)$")
    local prog = ((rows and tonumber(rows) > 0) and string.format("stty rows %d cols %d; ", rows, cols) or "")
        .. shquote(config.shell)
        .. "; echo $? > "
        .. shquote(rcfile)

    stdin_read, stdin_write = sys.pipe()
    stdout_read, stdout_write = sys.pipe()
    shell_child = sys.fork()
    if not shell_child then
        log("fork failed")
        os.exit(255)
    end

    if shell_child == 0 then
        sys.setpid("p", 0, 0)
        sys.dup2(stdin_read, 0)
        sys.dup2(stdout_write, 1)
        sys.dup2(stdout_write, 2)
        for fd = 3, 255 do
            sys.close(fd)
        end

        sys.setenv("SHELL", env("MZD_SCRIPT_SHELL") or "/bin/sh") -- the Terminal set SHELL to this program: script must not start it again
        sys.exec(env("MZD_BUSYBOX") or "/bin/busybox", "script", "-q", "-f", "-c", prog, "/dev/null")
        sys._exit(255)
    end

    sys.close(stdin_read)
    sys.close(stdout_write)

    -- the Terminal's pty (our stdin / stdout) to raw mode, so the shell's output is passed unchanged
    saved_tty = sh_out("stty -g")
    if saved_tty ~= "" then
        os.execute("stty raw -echo 2>/dev/null")
    end

    deadline = sys.uptime() + config.max_seconds

    -- The helper watches the Terminal (the bridge's parent unless --watch-pid is given).
    start_helper(
        config.watch_pid > 0 and config.watch_pid or ((pid_parent and pid_parent > 1) and pid_parent or pid_self),
        shell_child,
        pid_self,
        rcfile
    )
    scan_devices()
    update_hold()
    log("devices: %d", #devices)
    last_scan = sys.uptime()
end

-- Runs until HOME, the end of the shell, a closed Terminal, a signal or the time limit.
local function run_loop()
    while not done do
        local fds = wait_for_input()

        if config.max_seconds > 0 and sys.uptime() >= deadline then
            log("time limit")
            exit_code = 254
            reason = "time-limit"
            break
        end

        if got_term then
            log("terminated")
            reason = "terminated"
            break
        end

        if not pump_shell_output(fds) or not pump_terminal_input(fds) then
            break
        end

        pump_devices(fds)

        if child_gone then
            break
        end

        update_hold()
        if sys.uptime() - last_scan >= 1 then
            last_scan = sys.uptime()
            scan_devices()
        end
    end
end

-- Releases the held key first, stops the shell, restores the Terminal's pty, writes the reason and exits.
local function leave()
    leaving = true
    hold_release("leaving") -- first: the CMU listens to the keyboard again at once
    for i = #devices, 1, -1 do
        drop_dev(i)
    end

    if child_gone then
        local rc = tonumber((read_file(rcfile) or ""):match("%d+"))
        exit_code = rc or 0
        reason = "shell-exit " .. exit_code
    end

    os.remove(rcfile)
    sys.close(stdin_write)
    sys.kill(shell_child, posix.SIGHUP)
    sys.sleep_ms(200)
    do
        local w = sys.wait(shell_child, posix.WNOHANG or 1)
        if not w or w == 0 then
            sys.kill(shell_child, posix.SIGKILL)
            sys.wait(shell_child, 0)
        end
    end

    sys.close(stdout_read)
    if saved_tty ~= "" then
        os.execute("stty " .. saved_tty .. " 2>/dev/null")
    end

    if config.result then
        local rf = io.open(config.result, "w")
        if rf then
            rf:write(reason, "\n")
            rf:close()
        end
    end

    log("exit %d (%s)", exit_code, reason)
    if logf then
        logf:close()
    end

    os.exit(exit_code)
end

local function main()
    start_shell()
    run_loop()
    leave()
end

main()
