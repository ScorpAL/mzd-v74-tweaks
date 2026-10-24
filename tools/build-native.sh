#!/bin/sh
# Optional developer rebuild; runtime files are already checked in.
set -eu
cd "$(dirname "$0")/.."
for name in bridge browser-adapter; do
    output=shell-bridge-arm
    [ "$name" != browser-adapter ] || output=browser-adapter-arm
    zig cc -target arm-linux-musleabi -mcpu=cortex_a9 -std=c99 -Os -static -s -Wall -Wextra -Werror "src/$name.c" -o "bin/$output"
done
printf '%s\n' 'Refresh checksums and run contract/transport tests before committing.'
