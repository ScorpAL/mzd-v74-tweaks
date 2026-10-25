#!/bin/sh
set -u
HERE=/experiment/package
STATE=$1
HTTP_PID=
MZD_LOG_LEVEL=${2:-normal}; export MZD_LOG_LEVEL
export PATH=/experiment/bin:/usr/bin:/bin:/sbin
cd "$HERE" || exit 1
. "$HERE/lib/transport.sh" || exit 1
mzd_transport_start || { cat "$STATE/http.log"; exit 1; }
printf '%s\n' "$HTTP_PID" > "$STATE/pids"
wait "$HTTP_PID"; code=$?
exit "$code"
