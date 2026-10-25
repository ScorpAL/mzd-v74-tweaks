-- Browser transport wire format, including byte-preserving JSON strings.
local M={}
function M.string(value)
    local out={string.char(34)}
    local slash=string.char(92)
    for i=1,#value do
        local c=value:byte(i)
        if c==34 or c==92 then out[#out+1]=slash..string.char(c)
        elseif c<32 or c>=127 then out[#out+1]=string.format("%su%04x",slash,c)
        else out[#out+1]=string.char(c) end
    end
    out[#out+1]=string.char(34)
    return table.concat(out)
end
function M.result(r)
    local function number(n) return n and tostring(n) or "null" end
    return '{"started":'..tostring(r.started)..',"exitCode":'..number(r.exitCode)..',"signal":'..number(r.signal)..
        ',"stdout":'..M.string(r.stdout)..',"stderr":'..M.string(r.stderr)..',"startError":'..M.string(r.startError or "")..
        ',"stdoutTruncated":'..tostring(r.stdoutTruncated)..',"stderrTruncated":'..tostring(r.stderrTruncated)..'}'
end
local function decode(value)
    local result,i={},1
    while i<=#value do
        local c=value:sub(i,i)
        if c=="%" then
            local hex=value:sub(i+1,i+2)
            assert(#hex==2 and hex:match("^%x%x$"),"Invalid URL encoding")
            c=string.char(tonumber(hex,16));i=i+2
        elseif c=="+" then c=" " end
        assert(c~="\0","NUL in argument")
        result[#result+1]=c;i=i+1
    end
    local decoded=table.concat(result)
    assert(#decoded<=8192,"Argument too long")
    return decoded
end
function M.arguments(body)
    local values={}
    for pair in (body.."&"):gmatch("(.-)&") do
        local prefix=#values==0 and "program=" or "arg="
        assert(pair:sub(1,#prefix)==prefix and #values<64,"Invalid argument list")
        values[#values+1]=decode(pair:sub(#prefix+1))
    end
    local program=table.remove(values,1)
    assert(program and program:sub(1,1)=="/","Absolute program required")
    return program,values
end
return M
