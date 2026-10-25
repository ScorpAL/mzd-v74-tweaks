-- CMU Lua 5.1 / LuaPOSIX 5.1.19. No shell command strings or temporary output files.
local posix = require("posix")
local M = {limit=65536}
function M.check()
    for _, name in ipairs({"fork","exec","pipe","dup2","poll","read","write","wait","fcntl","close","open","_exit","signal","setpid","kill"}) do
        assert(type(posix[name])=="function", "Missing POSIX function: "..name)
    end
    assert(type(posix.F_SETFD)=="number", "POSIX F_SETFD is unavailable")
end
local function close(fd) if fd then posix.close(fd) end end
function M.run(program, args, inherited, trace, statusTimeout)
    M.check()
    local function note(message) if trace then trace(message) end end
    local function uptime()
        local f=assert(io.open("/proc/uptime","r"));local n=assert(f:read("*n"));f:close();return n
    end
    local began=statusTimeout and uptime() or nil
    local timedOut,killedAt=false,nil
    local streams, owned = {}, {}
    local function pipe()
        local a,b=posix.pipe()
        if not a then for _,fd in ipairs(owned) do close(fd) end;error("Cannot create process pipe") end
        owned[#owned+1]=a;owned[#owned+1]=b
        return a,b
    end
    local outR,outW=pipe();local errR,errW=pipe();local startR,startW=pipe()
    -- FD_CLOEXEC is Linux bit 1; this old CMU module exports F_SETFD but not the bit.
    if not posix.fcntl(startW,posix.F_SETFD,1) then
        for _,fd in ipairs(owned) do close(fd) end;error("Cannot protect exec-status pipe")
    end
    local pid, forkError=posix.fork()
    if not pid then
        for _,fd in ipairs(owned) do close(fd) end
        return {started=false,startError=forkError,stdout="",stderr="",stdoutTruncated=false,stderrTruncated=false}
    end
    if pid==0 then
        close(outR);close(errR);close(startR)
        for _,fd in ipairs(inherited or {}) do close(fd) end
        local function failed(message)
            posix.write(startW,tostring(message));posix._exit(127)
        end
        if statusTimeout and not posix.setpid("p",0,0) then failed("Cannot isolate status process group") end
        local input, message=posix.open("/dev/null",{"rdonly"})
        if not input then failed(message) end
        if not posix.dup2(input,0) or not posix.dup2(outW,1) or not posix.dup2(errW,2) then failed("Cannot redirect process streams") end
        if input>2 then close(input) end
        if outW>2 then close(outW) end
        if errW>2 then close(errW) end
        local _, message=posix.exec(program,unpack(args))
        failed(message)
    end
    close(outW);close(errW);close(startW)
    note("worker pid="..pid.." forked")
    local heartbeat=os.time()
    local function add(fd,limit)
        streams[fd]={events={IN=true},parts={},length=0,limit=limit,truncated=false}
        return streams[fd]
    end
    local output=add(outR,M.limit);local errors=add(errR,M.limit);local started=add(startR,8192)
    local streamError
    local function enforceDeadline()
        if statusTimeout then
            local now=uptime()
            if not timedOut and now-began>=statusTimeout then
                timedOut=true;killedAt=now
                note("read-only status timeout; stopping process group "..pid)
                posix.kill(-pid,posix.SIGTERM)
            elseif timedOut and killedAt and now-killedAt>=2 then
                posix.kill(-pid,posix.SIGKILL);killedAt=nil
            end
        end
    end
    while next(streams) do
        enforceDeadline()
        if os.time()-heartbeat>=5 then
            local open=0;for _ in pairs(streams) do open=open+1 end
            note("worker pid="..pid.." waiting; pipes="..open.." stdout="..output.length.." stderr="..errors.length)
            heartbeat=os.time()
        end
        local count,message,errno=posix.poll(streams,250)
        if not count and errno~=4 then error("Process poll failed: "..tostring(message)) end
        if count and count>0 then
            for fd,s in pairs(streams) do
                local events=s.revents or {}
                if events.IN or events.HUP or events.ERR or events.NVAL then
                    local data,readError,readErrno=posix.read(fd,4096)
                    if not data and readErrno~=4 then
                        streamError=readError;close(fd);streams[fd]=nil
                    elseif data=="" then close(fd);streams[fd]=nil
                    elseif data then
                        local remaining=s.limit-s.length
                        if #data>remaining then s.truncated=true end
                        if remaining>0 then
                            data=data:sub(1,remaining);s.parts[#s.parts+1]=data;s.length=s.length+#data
                        end
                    end
                end
            end
        end
    end
    note("worker pid="..pid.." pipes drained; collecting exit")
    local waited,reason,status
    repeat
        enforceDeadline()
        waited,reason,status=posix.wait(pid,statusTimeout and (posix.WNOHANG or 1) or 0)
        if waited==0 then posix.poll({},100) end
    until (waited and waited>0) or (not waited and status~=4)
    if not waited or streamError then error("Unknown process outcome: "..tostring(streamError or reason)) end
    note("worker pid="..pid.." reason="..tostring(reason).." status="..tostring(status))
    local startError=table.concat(started.parts)
    if timedOut then
        return {started=true,startError="",exitCode=1,stdout=table.concat(output.parts),
            stderr="Status check timed out after "..statusTimeout.." seconds. Only the read-only check was stopped.\n"..table.concat(errors.parts),
            stdoutTruncated=output.truncated,stderrTruncated=errors.truncated}
    end
    return {started=startError=="",startError=startError,exitCode=reason=="exited" and status or nil,
        signal=reason=="killed" and status or nil,stdout=table.concat(output.parts),stderr=table.concat(errors.parts),
        stdoutTruncated=output.truncated,stderrTruncated=errors.truncated}
end
return M
