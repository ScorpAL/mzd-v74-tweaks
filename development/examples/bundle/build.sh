#!/bin/sh
# Developer step only. The ready-to-run tweak ships the compiled asset.
# Usage: CC=/path/to/arm-...-gcc sh build.sh, or sh build.sh /path/to/m3-toolchain.
set -eu
HERE=$(CDPATH= cd "$(dirname "$0")" && pwd)
compiler=${CC:-arm-cortexa9_neon-linux-gnueabi-gcc}
if [ "$#" -gt 0 ]; then compiler="$1/bin/arm-cortexa9_neon-linux-gnueabi-gcc"; fi
command -v "$compiler" >/dev/null 2>&1 || {
    printf 'Provide the CMU ARM EABI soft-float compiler via CC or the toolchain path.\n' >&2
    exit 1
}
mkdir -p "$HERE/assets"
for name in alpha beta; do
"$compiler" -march=armv7-a -mtune=cortex-a9 -mfpu=neon -mfloat-abi=softfp \
    -fPIC -shared -nostdlib -fvisibility=hidden -Wl,--build-id=none \
    -Wl,-soname,"$name.so" -o "$HERE/assets/$name.so" "$HERE/shim-example.c"
printf 'Built %s\n' "$HERE/assets/$name.so"
done
