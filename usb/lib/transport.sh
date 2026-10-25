#!/bin/sh
# Start the factory Lua runtime; no compiled helpers or selector.
mzd_transport_alive() {
    kill -0 "$HTTP_PID" 2>/dev/null
}
mzd_transport_start() {
    TRANSPORT_BACKEND=lua
    command -v lua >/dev/null 2>&1 || { printf 'CMU Lua interpreter is unavailable.\n' >&2; return 1; }
    [ -f "$HERE/lib/lua-bridge/server.lua" ] || return 1
    lua "$HERE/lib/lua-bridge/server.lua" --check > "$STATE/http.log" 2>&1 || return 1
    lua "$HERE/lib/lua-bridge/server.lua" "$HERE/ui/transport.html" "$STATE/ready" >> "$STATE/http.log" 2>&1 &
    HTTP_PID=$!
    for n in 1 2 3 4 5 6 7 8 9 10; do [ -s "$STATE/ready" ] && break; sleep 1; done
    [ -s "$STATE/ready" ] && mzd_transport_alive
}
