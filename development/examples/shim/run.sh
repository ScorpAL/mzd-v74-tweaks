#!/bin/sh
# Shared loader/payload transaction; this example library changes no functions.
set -u
SELF=$(readlink -f "$0") || exit 1
HERE=$(dirname "$SELF")
ROOT=$(CDPATH= cd "$HERE/../.." && pwd) || exit 1
. "$ROOT/lib/shim.sh" || exit 1
mzd_shim_main "$@"
