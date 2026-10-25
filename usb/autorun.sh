#!/bin/sh
# Start bridge, then the separate styled menu. Uses the confirmed test-6 path.
set -u
umask 077
SELF=$(readlink -f "$0") || exit 1
HERE=$(dirname "$SELF")
STATE=$(mktemp -d /tmp/cmu-installer.XXXXXX) || exit 1
INSTALLER_STATE=$STATE; export INSTALLER_STATE
LOG_DIR="$HERE/installer-logs/$(date +%Y%m%d-%H%M%S)-$$"
INSTALLER_LOG=$LOG_DIR; export INSTALLER_LOG
BRIDGE_PID=''; HTTP_PID=''; OPERA_PID=''; ACTIVE=0; USB_CHANGED=0; USB_MOUNT=''
checkpoint() { printf '%s %s\n' "$(date +%H:%M:%S)" "$*" >> "$STATE/launcher.log"; }
save_logs() {
  [ -d "$LOG_DIR" ] || return 0
  for name in launcher.log bridge.log http.log opera.log native.log; do
    [ ! -f "$STATE/$name" ] || cp "$STATE/$name" "$LOG_DIR/$name" 2>/dev/null || :
  done
  sync
}
native_surface() {
  /usr/bin/dbus-send --address=unix:path=/tmp/dbus_hmi_socket --type=method_call --print-reply --reply-timeout=2000 --dest=com.jci.nativeguictrl /com/jci/nativeguictrl com.jci.nativeguictrl.SetRequiredSurfaces "string:$1" int16:0
}
finish() {
  code=$?; trap - 0
  # Normal Exit first returns keyboard focus through the native JS plugin.
  # The direct D-Bus API is the additional, vehicle-confirmed visibility path.
  if [ "$ACTIVE" = 1 ]; then native_surface 9 >> "$STATE/native.log" 2>&1 || checkpoint 'Primary fallback request failed'; fi
  if [ -n "$OPERA_PID" ]; then kill "$OPERA_PID" 2>/dev/null || :; wait "$OPERA_PID" 2>/dev/null || :; fi
  # A progress-enabled export is detached from the short bridge request. If the
  # browser disappears, let that export finish before changing USB mount state.
  for job in "$STATE"/job.*; do
    [ -d "$job" ] || continue
    for pid_file in pid worker.pid; do
      [ ! -f "$job/done" ] || break
      pid=$(cat "$job/$pid_file" 2>/dev/null)
      case "$pid" in ''|*[!0-9]*) continue ;; esac
      while kill -0 "$pid" 2>/dev/null && [ ! -f "$job/done" ]; do
        tr '\000' ' ' < "/proc/$pid/cmdline" 2>/dev/null | grep -Fq "$HERE/" || break
        sleep 1
      done
    done
  done
  # The bridge completes an already-running worker before it exits. Do not
  # terminate an install worker just because the browser has disappeared.
  for pid in "$HTTP_PID" "$BRIDGE_PID"; do
    if [ -n "$pid" ]; then kill "$pid" 2>/dev/null || :; wait "$pid" 2>/dev/null || :; fi
  done
  checkpoint "Installer closed; exit=$code"; save_logs
  if [ "$USB_CHANGED" = 1 ]; then
    if ! mount -o ro,remount "$USB_MOUNT"; then
      code=1
      checkpoint 'ERROR: Could not restore USB read-only state.'; save_logs
      printf 'Could not restore USB read-only state. See installer-logs on USB.\n' >&2
    fi
  fi
  exit "$code"
}
fail() {
  checkpoint "ERROR: $*"; save_logs
  printf 'ERROR: %s\nLogs: installer-logs on USB.\n' "$*" >&2
  exit 1
}
trap finish 0
trap 'exit 130' INT
trap 'exit 143' TERM
MP=$HERE
while [ "$MP" != / ]; do
  MODE=$(awk -v p="$MP" '$2==p {print $4; exit}' /proc/mounts)
  [ -z "$MODE" ] || break
  MP=$(dirname "$MP")
done
[ "$MP" != / ] || fail 'Cannot identify USB mount.'
USB_MOUNT=$MP
case ",$MODE," in *,ro,*) mount -o rw,remount "$MP" || fail 'Cannot write USB logs.'; USB_CHANGED=1 ;; esac
mkdir -p "$LOG_DIR" || fail 'Cannot create USB logs.'
printf 'USB logging ready\n' > "$LOG_DIR/write-check.txt" || fail 'USB logs are not writable.'
checkpoint 'USB logging ready'
# The styled UI owns the startup notice and Exit. Never block on jci-dialog.
export XDG_RUNTIME_DIR=/tmp
export WAYLAND_DISPLAY=${WAYLAND_DISPLAY:-wayland-0}
export WAYLAND_IVI_SURFACE_ID=2
export OPERA_DIR=/jci/opera/opera_dir
export OPERA_FONTS=/jci/fonts/CHN
export FREETYPE_FONT_SET=YES
export JCI_HMI_BUS=unix:path=/tmp/dbus_hmi_socket
export JCI_SERVICE_BUS=unix:path=/tmp/dbus_service_socket
export DBUS_SESSION_BUS_ADDRESS=$JCI_HMI_BUS
export DBUS_STARTER_ADDRESS=$JCI_HMI_BUS
export DBUS_SYSTEM_BUS_ADDRESS=$JCI_SERVICE_BUS
export LD_LIBRARY_PATH="/jci/lib:/jci/opera/3rdpartylibs/freetype:/usr/lib/imx-mm/audio-codec:/usr/lib/imx-mm/parser:/data_persist/dev/lib:${LD_LIBRARY_PATH:-}"
[ -S "$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY" ] || fail 'CMU Wayland socket is missing.'
[ -x /usr/bin/dbus-send ] || fail 'Native surface activation is unavailable.'
[ -d /jci/opera/opera_home ] || fail 'Original Opera profile is missing.'
cp -R /jci/opera/opera_home "$STATE/opera-home" || fail 'Cannot create private RAM profile.'
export OPERA_HOME="$STATE/opera-home/"
cp "$HERE/bin/shell-bridge-arm" "$STATE/bridge" || fail 'Cannot copy ARM bridge.'
cp "$HERE/bin/browser-adapter-arm" "$STATE/http" || fail 'Cannot copy HTTP adapter.'
chmod 700 "$STATE/bridge" "$STATE/http" || exit 1
cd "$HERE" || exit 1
"$STATE/bridge" "$STATE/exec.sock" > "$STATE/bridge.log" 2>&1 &
BRIDGE_PID=$!
for n in 1 2 3 4 5; do [ -S "$STATE/exec.sock" ] && break; sleep 1; done
[ -S "$STATE/exec.sock" ] || fail 'ARM bridge did not start.'
"$STATE/http" "$STATE/exec.sock" "$HERE/ui/transport.html" "$STATE/ready" > "$STATE/http.log" 2>&1 &
HTTP_PID=$!
for n in 1 2 3 4 5; do [ -s "$STATE/ready" ] && break; sleep 1; done
[ -s "$STATE/ready" ] || fail 'HTTP adapter did not start.'
PORT=$(sed -n '1p' "$STATE/ready"); TOKEN=$(sed -n '2p' "$STATE/ready")
case "$PORT" in ''|*[!0-9]*) fail 'Invalid adapter port.' ;; esac
case "$TOKEN" in ''|*[!0-9a-f]*) fail 'Invalid adapter token.' ;; esac
mkdir "$STATE/ui" || exit 1
cp "$HERE/ui/style.css" "$HERE/ui/app.js" "$STATE/ui/" || fail 'Cannot copy menu assets.'
sed -e "s|@ORIGIN@|http://127.0.0.1:$PORT|g" -e "s|@TOKEN@|$TOKEN|g" "$HERE/ui/index-template.html" > "$STATE/ui/index.html" || fail 'Cannot prepare menu.'
checkpoint 'Launching Secondary Opera'
(
  cd /jci/opera || exit 1
  exec /jci/opera/opera --secondary --noWatchdogs -u "file://localhost$STATE/ui/index.html"
) > "$STATE/opera.log" 2>&1 &
OPERA_PID=$!; ACTIVE=1; ACTIVATED=0; SECONDS_WAITED=0
while [ ! -f "$STATE/ui-close" ]; do
  kill -0 "$OPERA_PID" 2>/dev/null || fail 'Secondary Opera exited. Any active worker will be allowed to finish.'
  kill -0 "$HTTP_PID" 2>/dev/null && kill -0 "$BRIDGE_PID" 2>/dev/null || fail 'Shell transport stopped.'
  if [ "$ACTIVATED" = 0 ]; then
    if [ -f "$STATE/ui-ready" ]; then
      # Numeric 10 is SECONDARY in the original native controller. This exact
      # extra call made the display sweep's TEST 6 visible and interactive.
      native_surface 10 >> "$STATE/native.log" 2>&1 || fail 'Secondary visibility request failed.'
      ACTIVATED=1; checkpoint 'Secondary visibility requested through direct D-Bus'
    elif [ "$SECONDS_WAITED" -ge 30 ]; then fail 'Menu did not report ready within 30 seconds.'; fi
  fi
  case "$SECONDS_WAITED" in *0|*5) save_logs ;; esac
  sleep 1; SECONDS_WAITED=$((SECONDS_WAITED + 1))
done
checkpoint 'Menu requested Exit'
exit 0
