#!/bin/sh

# Opens the CMU Terminal with full USB keyboard support. ../run.sh calls it as: terminal.sh --wait --hold --hint TEXT
#
# The stock /jci/scripts/run-terminal.sh is patched in memory and run from there (no file of the CMU is changed). This fixes:
#   - the CMU drops a key pressed while another one is held (no Shift+key, Ctrl+key or fast typing): the Terminal's shell
#     becomes the bridge, which reads the raw keyboard and runs /bin/sh on a pty of its own;
#   - the CMU screen behind the Terminal reacts to the keyboard: with --hold the bridge keeps one key pressed on the
#     multicontroller's virtual keyboard, which makes the CMU ignore the USB keyboard (details in the bridge);
#   - the stock script gives the keyboard focus to the Terminal and never takes it back, which leaves the multicontroller
#     dead: a hook returns the focus when the Terminal is gone.
# The font size is changed too, and the window transparency if TERMINAL_ALPHA is set below.
# Nothing is opened if the bridge is missing or the stock script is not the expected one: a stock Terminal would leave the
# multicontroller dead.
#
# Usage: sh terminal.sh [--wait] [--hold] [--timeout SECONDS] [--hint TEXT] [--rc FILE] [--bridge FILE] [--log FILE]
#   --wait      return when the Terminal is closed and the focus is back (default: return as soon as it is open)
#   --hold      make the CMU ignore the USB keyboard
#   --timeout N close the Terminal after N seconds (default: no time limit)
#   --hint      text printed in the Terminal first; | starts a new line
#   --rc        a file of shell commands run first in the Terminal
#   --bridge    the bridge to use (default: mzd-kbd-bridge.lua next to this file, with posixcompat.lua)
#   --log       diagnostics: a line per step in FILE (the bridge log goes next to it). Off by default
# Environment: MZD_SURFACE and MZD_RETURN_SURFACE (see below); MZD_TMP, MZD_STOCK, MZD_IVI, MZD_TERMINAL_BIN, MZD_DBUS_SEND,
# MZD_HMI_BUS replace the system paths (tests).
# Exit code: 0 opened (with --wait: and closed), 1 closed by the time limit, 2 could not be opened, 3 already open.

SELF=$(readlink -f "$0")
SCRIPT_DIR=$(dirname "$SELF")

# ---------------------------------------------------------------- settings
: "${MZD_TMP:=/tmp}"
: "${MZD_STOCK:=/jci/scripts/run-terminal.sh}"
: "${MZD_IVI:=/usr/bin/ivi-shell}"
: "${MZD_TERMINAL_BIN:=/usr/bin/terminal}"
# The surface that gets the keyboard focus back when the Terminal is gone. The launcher is the secondary Opera and sets
# MZD_SURFACE=JCI_OPERA_SECONDARY.
: "${MZD_SURFACE:=JCI_OPERA_PRIMARY}"
# Number of the native surface to show again when the Terminal is gone (10 = secondary Opera, 9 = primary). The CMU may switch
# to its own screens meanwhile (HOME key). Empty = only the focus is returned.
: "${MZD_RETURN_SURFACE:=}"
: "${MZD_DBUS_SEND:=/usr/bin/dbus-send}"
: "${MZD_HMI_BUS:=unix:path=/tmp/dbus_hmi_socket}"

TERMINAL_FONT_SIZE=20
TERMINAL_ALPHA=          # window transparency, 0-255, for debugging. Empty = the stock value
TERMINAL_TIMEOUT=0       # seconds; 0 = no time limit
TERMINAL_OPEN_WAIT=15    # seconds to wait for the Terminal to appear

# Set by the options
BRIDGE_SRC="$SCRIPT_DIR/mzd-kbd-bridge.lua"
WAIT=0
HINT=""
RCFILE=""
LOG=""

# Temporary files, all in RAM. The bridge copy keeps its name: it shows in the process list.
# RC: commands run first in the Terminal. HOOK: run when the Terminal is gone. RESULT: why the bridge ended (written by the
# bridge). FLAG: written by the hook; the wait loop at the end waits for it.
LOCK="$MZD_TMP/mzd-terminal.lock"
BRIDGE="$MZD_TMP/mzd-kbd-bridge"
RC="$MZD_TMP/mzd-terminal-rc"
HOOK="$MZD_TMP/mzd-terminal-hook.sh"
FLAG="$MZD_TMP/mzd-terminal.done"
RESULT="$MZD_TMP/mzd-terminal.result"

# ---------------------------------------------------------------- helpers
# sync: the log is usually on a USB drive that can be pulled at any moment.
log() {
  [ -n "$LOG" ] && { echo "[$(date +%T)] terminal: $1" >> "$LOG"; sync; }
  return 0
}

# The stock script starts /usr/bin/terminal in the background.
terminal_running() {
  ls -l /proc/[0-9]*/exe 2>/dev/null | grep -q " -> .*/terminal\$"
}

clean() {
  rm -f "$RC" "$HOOK" "$FLAG" "$RESULT" "$BRIDGE" "$MZD_TMP/posixcompat.lua" "$LOCK/pid"
  rmdir "$LOCK" 2>/dev/null
  return 0
}

# Stops before the Terminal is started: log the reason, clean up, exit with code 2.
refuse() {
  log "$1"
  clean
  exit 2
}

# ---------------------------------------------------------------- steps
parse_options() {
  while [ "$#" -gt 0 ]
  do
    case "$1" in
      --wait) WAIT=1 ;;
      --timeout) TERMINAL_TIMEOUT=$2; [ "$#" -gt 1 ] && shift ;;
      --hint) HINT=$2; [ "$#" -gt 1 ] && shift ;;
      --rc) RCFILE=$2; [ "$#" -gt 1 ] && shift ;;
      --bridge) BRIDGE_SRC=$2; [ "$#" -gt 1 ] && shift ;;
      --hold) export MZD_KBD_HOLD=194 ;;
      --log) LOG=$2; [ "$#" -gt 1 ] && shift ;;
    esac
    shift
  done
}

check_system() {
  if [ ! -f "$MZD_STOCK" ] || [ ! -x "$MZD_TERMINAL_BIN" ] || [ ! -x "$MZD_IVI" ]
  then
    log "not available here (stock script, terminal or ivi-shell missing)"
    exit 2
  fi
}

# One Terminal at a time. A lock whose owner is gone is removed.
take_lock() {
  if ! mkdir "$LOCK" 2>/dev/null
  then
    lock_owner=$(cat "$LOCK/pid" 2>/dev/null)
    if [ -n "$lock_owner" ] && kill -0 "$lock_owner" 2>/dev/null
    then
      log "another one is open (owner $lock_owner)"
      exit 3
    fi

    clean
    mkdir "$LOCK" 2>/dev/null || { log "cannot take the lock"; exit 2; }
  fi

  echo $$ > "$LOCK/pid"
  rm -f "$FLAG" "$RESULT"
}

# The bridge and its helper module are copied to RAM. The bridge must start, or nothing is opened.
install_bridge() {
  bridge_dir=${BRIDGE_SRC%/*}
  if [ ! -f "$BRIDGE_SRC" ] || [ ! -f "$bridge_dir/posixcompat.lua" ]
  then
    refuse "bridge: $BRIDGE_SRC or posixcompat.lua is missing, nothing started"
  fi

  if ! { cp "$BRIDGE_SRC" "$BRIDGE" && cp "$bridge_dir/posixcompat.lua" "$MZD_TMP/posixcompat.lua" && chmod +x "$BRIDGE"; }
  then
    refuse "bridge: cannot copy it to $MZD_TMP, nothing started"
  fi

  bridge_version=$("$BRIDGE" --version 2>&1)
  if [ "$?" -ne 0 ]
  then
    refuse "bridge: cannot run ($bridge_version), nothing started"
  fi

  log "bridge: $bridge_version"
}

# RC is sourced by the Terminal's shell through $ENV: prompt, hint, then the --rc commands.
write_rc() {
  {
    echo "PS1='mzd> '"
    printf '%s\n' "$HINT" | tr '|' '\n' | while IFS= read -r hint_line
    do
      [ -n "$hint_line" ] && printf "echo '%s'\n" "$(printf '%s' "$hint_line" | sed "s/'/'\\\\''/g")"
    done
    [ -n "$RCFILE" ] && [ -f "$RCFILE" ] && cat "$RCFILE"
  } > "$RC"
}

# The hook returns the focus (and the launcher's screen) when the Terminal is gone.
# It is a file of its own because the bridge's janitor runs it after the Terminal, and without --wait this script, are gone.
write_hook() {
  {
    echo '#!/bin/sh'
    echo 'export XDG_RUNTIME_DIR=/tmp'
    echo 'say() { [ -n "'"$LOG"'" ] && echo "[$(date +%T)] terminal hook: $1" >> "'"$LOG"'"; return 0; }'
    echo 'say start'

    if [ -n "$MZD_RETURN_SURFACE" ]
    then
      show_surface="'$MZD_DBUS_SEND' --address='$MZD_HMI_BUS' --type=method_call --print-reply --reply-timeout=2000"
      show_surface="$show_surface --dest=com.jci.nativeguictrl /com/jci/nativeguictrl"
      show_surface="$show_surface com.jci.nativeguictrl.SetRequiredSurfaces 'string:$MZD_RETURN_SURFACE' int16:0"
      echo "$show_surface > /dev/null 2>&1; say \"surface rc=\$?\""
    fi

    echo "'$MZD_IVI' -f '$MZD_SURFACE' > /dev/null 2>&1; say \"focus rc=\$?\""
    echo 'sleep 1'
    echo "'$MZD_IVI' -f '$MZD_SURFACE' > /dev/null 2>&1; say \"focus again rc=\$?\""
    echo "cat '$RESULT' > '$FLAG' 2>/dev/null || echo unknown > '$FLAG'"

    if [ "$WAIT" -eq 0 ]
    then
      # nothing waits for the result (no --wait): the hook removes the files itself, itself last
      echo 'sleep 1'
      echo "rm -f '$RC' '$FLAG' '$RESULT' '$BRIDGE' '$MZD_TMP/posixcompat.lua' '$LOCK/pid'"
      echo "rmdir '$LOCK' 2>/dev/null"
      echo 'say "done, files removed"'
      echo "rm -f '$HOOK'"
    else
      echo 'say done'
    fi
  } > "$HOOK"
  chmod +x "$HOOK"
}

# The stock script with the changed lines, in PATCHED. Each must match exactly, otherwise this is another firmware.
# 1: the stock script empties weston.ini, here it sets the font size. 2: the Terminal's shell becomes the bridge.
# 3: only with TERMINAL_ALPHA, the window transparency.
patch_stock_script() {
  font_old='echo "" > /tmp/root/weston.ini'
  font_new="{ echo '[terminal]'; echo 'font-size=${TERMINAL_FONT_SIZE}'; } > /tmp/root/weston.ini"
  shell_old="export SHELL='/bin/sh'"
  shell_new="export SHELL='${BRIDGE}'"
  alpha_old='ivi-shell -a "Wayland Terminal":255 > /dev/null &'
  alpha_new="ivi-shell -a \"Wayland Terminal\":${TERMINAL_ALPHA} > /dev/null \\&"   # \& : a plain & in a sed replacement means "the matched text"

  # the sed script, built in the positional parameters
  set -- -e "s|^${font_old}\$|${font_new}|" -e "s|^${shell_old}\$|${shell_new}|"
  expected=2
  if [ -n "$TERMINAL_ALPHA" ]
  then
    set -- "$@" -e "s|^${alpha_old}\$|${alpha_new}|"
    expected=3
  fi

  PATCHED=$(sed "$@" "$MZD_STOCK")

  # every line that was changed must be there
  matched=$(printf '%s\n' "$PATCHED" | grep -c -e "font-size=${TERMINAL_FONT_SIZE}" -e "$BRIDGE")
  if [ -n "$TERMINAL_ALPHA" ] && printf '%s\n' "$PATCHED" | grep -q -e "Terminal\":${TERMINAL_ALPHA} "
  then
    matched=$((matched + 1))
  fi

  if [ -z "$PATCHED" ] || [ "$matched" -lt "$expected" ]
  then
    refuse "the stock script does not have the expected lines ($matched of $expected), nothing started"
  fi

  if [ -n "$LOG" ]
  then
    # ${LOG%/*} inside a redirection breaks the CMU's ash: use a variable
    log_dir=${LOG%/*}
    printf '%s\n' "$PATCHED" > "$log_dir/patched-run-terminal.sh"
  fi
}

# End of a session. The bridge starts a janitor process that outlives the bridge and the Terminal; when the Terminal is gone,
# however it ended, the janitor runs the hook. The bridge also writes the reason (home, shell-exit N, time-limit, terminated)
# into RESULT, the hook copies it into FLAG.
run_stock_script() {
  export MZD_KBD_ON_EXIT="sh $HOOK" MZD_KBD_RESULT_FILE="$RESULT"

  log "start (wait=$WAIT, timeout=$TERMINAL_TIMEOUT s, font=$TERMINAL_FONT_SIZE, alpha=${TERMINAL_ALPHA:-stock})"
  (
    export ENV="$RC"
    [ "$TERMINAL_TIMEOUT" -gt 0 ] && export MZD_KBD_MAX_SECONDS="$TERMINAL_TIMEOUT"
    [ -n "$LOG" ] && export MZD_KBD_LOG="${LOG%/*}/kbd-bridge.log" MZD_KBD_VERBOSE=1
    sh -c "$PATCHED" >> "${LOG:-/dev/null}" 2>&1
  )
}

# The stock script returns after about a second; the Terminal needs a moment to appear.
wait_until_open() {
  waited=0
  while [ "$waited" -lt "$TERMINAL_OPEN_WAIT" ] && ! terminal_running
  do
    sleep 1
    waited=$((waited + 1))
  done

  if ! terminal_running
  then
    refuse "did not open in $TERMINAL_OPEN_WAIT s"
  fi

  log "open"
}

# Waits until the Terminal is closed and the hook has run. Normally the hook writes FLAG. After the time limit the Terminal is
# closed here (stage 1, exit code 1); if no hook has run 20 s later, the hook is run here (stage 2, exit code 2).
wait_until_closed() {
  wait_started=$(date +%s)
  stage=0
  while [ ! -f "$FLAG" ]
  do
    if [ "$stage" -eq 0 ] && [ "$TERMINAL_TIMEOUT" -gt 0 ] && [ $(( $(date +%s) - wait_started )) -ge $((TERMINAL_TIMEOUT + 5)) ]
    then
      log "time is up, closing it"
      stage=1
      killall -q terminal 2>/dev/null
      sleep 1
      terminal_running && killall -q -9 terminal 2>/dev/null
      closed_at=$(date +%s)
    fi

    if [ "$stage" -eq 1 ] && [ $(( $(date +%s) - closed_at )) -ge 20 ]
    then
      log "the hook did not run in 20 s, running it here"
      sh "$HOOK"
      stage=2
      [ -f "$FLAG" ] || break
    fi

    sleep 1
  done

  reason=$(cat "$FLAG" 2>/dev/null)
  log "closed (reason: ${reason:-none})"
  clean

  [ "$stage" -eq 2 ] && exit 2
  [ "$stage" -eq 1 ] && exit 1
  [ "$reason" = time-limit ] && exit 1
  exit 0
}

# ---------------------------------------------------------------- main
parse_options "$@"
check_system
take_lock
install_bridge
write_rc
write_hook
patch_stock_script
run_stock_script
wait_until_open

[ "$WAIT" -eq 1 ] || exit 0

wait_until_closed
