#!/bin/sh
# System Restore restores the loader files before removing this shim payload.
set -u
SELF=$(readlink -f "$0") || exit 1
HERE=$(dirname "$SELF")
ROOT=$(CDPATH= cd "$HERE/../.." && pwd) || exit 1
. "$ROOT/lib/shim.sh" || exit 1
mzd_shim_reset_main "$@"
