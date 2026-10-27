-- The calls of LuaPOSIX 5.1.19 (the CMU's) that the bridge uses, plus small helpers that this version lacks. Only functions
-- known to exist there are relied on: those of usb/lib/lua-bridge/process.lua, setenv and open() with the flag name "nonblock".
local posix = require("posix")
local M = { raw = posix } -- the posix module itself: the bridge also calls read, write and the constants directly

for _, name in ipairs({ "fork", "exec", "pipe", "dup2", "close", "read", "write", "wait", "kill", "setpid", "_exit" }) do
    M[name] = posix[name]
end

-- poll({ [fd] = { events = { IN = true } } }, milliseconds) fills in `revents` of every entry and returns how many are ready
local poll = posix.poll
M.poll = poll
M.signal = posix.signal -- signal(number, handler or "SIG_IGN")
M.setenv = posix.setenv

-- Non-blocking open, read-only; read/write if rw is true, falling back to read-only when writing is not permitted.
function M.open_nonblock(path, rw)
    local fd, err = posix.open(path, { rw and "rdwr" or "rdonly", "nonblock" })
    if not fd and rw then
        fd, err = posix.open(path, { "rdonly", "nonblock" })
    end
    return fd, err
end

-- seconds since boot with 10 ms resolution (no time functions that need librt)
function M.uptime()
    local f = io.open("/proc/uptime", "r")
    if not f then
        return os.time()
    end

    local n = f:read("*n")
    f:close()
    return n or os.time()
end

-- pid and parent pid of this process, from /proc (there is no getppid)
function M.self_ids()
    local f = io.open("/proc/self/stat", "r")
    if not f then
        return nil
    end

    local line = f:read("*a")
    f:close()
    local pid, ppid = line:match("^(%d+) %b() %a (%d+)")
    return tonumber(pid), tonumber(ppid)
end

-- Is the process gone, or only a zombie?
function M.pid_gone(pid)
    local f = io.open("/proc/" .. pid .. "/stat", "r")
    if not f then
        return true
    end

    local line = f:read("*a")
    f:close()
    return line:match("%) (%a)") == "Z"
end

-- Sleeps by polling no descriptors
function M.sleep_ms(ms)
    poll({}, ms)
end

return M
