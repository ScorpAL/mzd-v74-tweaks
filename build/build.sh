#!/bin/sh
# Builds every shim in mazda/patches/<name>/ into jci-shims/<name>.so and writes
# jci-shims/<name>.so.md5 (the installers read the expected md5 from that file).
#
# Usage (Linux x86_64):  sh build/build.sh [path/to/m3-toolchain]
#   default toolchain: the mazda/m3-toolchain submodule
#   (git submodule update --init mazda/m3-toolchain; it uses Git LFS)
#
# The shims link only against libc/libdl/libpthread: the head unit's old glibc has
# clock_gettime in librt, so do not use time functions other than time().
set -e
ROOT=$(cd "$(dirname "$0")/.." && pwd)
TC="${1:-$ROOT/mazda/m3-toolchain}"
CC="$TC/bin/arm-cortexa9_neon-linux-gnueabi-gcc"
SYSROOT="$TC/arm-cortexa9_neon-linux-gnueabi/sysroot"
if [ ! -x "$CC" ]
then
  echo "ERROR: $CC not found (m3-toolchain missing or Git LFS files not pulled)" >&2
  exit 1
fi
cd "$ROOT"
mkdir -p jci-shims
for d in mazda/patches/*/
do
  name=$(basename "$d")
  # Relative paths keep the output identical wherever the repo is checked out.
  "$CC" -march=armv7-a -mtune=cortex-a9 -mfpu=neon --sysroot="$SYSROOT" \
      -std=gnu99 -O2 -Wall -Wextra -fPIC -shared -fvisibility=hidden \
      -o "jci-shims/${name}.so" "mazda/patches/${name}"/*.c -ldl -lpthread
  (cd jci-shims && md5sum "${name}.so" > "${name}.so.md5")
  echo "built jci-shims/${name}.so  $(cut -c1-32 "jci-shims/${name}.so.md5")"
done
