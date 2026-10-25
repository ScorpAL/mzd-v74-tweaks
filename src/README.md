# Native shell bridge

The checked-in usb/bin/shell-bridge-arm and usb/bin/browser-adapter-arm are ready to run.
Source: bridge.c, browser-adapter.c and protocol.h. Runtime uses a private Unix
socket and loopback HTTP adapter with a per-session token. The parent launcher
owns their lifecycle; JavaScript uses separate program/argument values.

Optional rebuild: install Zig 0.13.0 on a development machine and run
`sh tools/build-native.sh`. No rebuild is needed to copy the contents of usb/ to the stick.
The current binaries target static arm-linux-musleabi, Cortex-A9. The musl license
is included under usb/licenses/. Changing native code requires rebuilding both the
relevant binary and reviewing actual CMU behavior.
