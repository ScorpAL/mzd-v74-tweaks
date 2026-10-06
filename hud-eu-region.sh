#!/bin/sh
# HUD Settings Europe Region mod installer/uninstaller for Mazda CMU

hwclock --hctosys

echo 1 > /sys/class/gpio/Watchdog\ Disable/value
mount -o rw,remount /

MYDIR=$(dirname "$(readlink -f "$0")")
mount -o rw,remount ${MYDIR}

# --- Require CMU firmware V74.00.324 ---
get_cmu_ver()
{
  _ver=$(grep '^JCI_SW_VER=' /jci/version.ini \
    | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n1)
  echo ${_ver}
}

CMU_VER=$(get_cmu_ver)
if [ "${CMU_VER}" != "74.00.324" ]
then
  /jci/tools/jci-dialog --info \
    --title="HUD Settings Europe Region" \
    --text="This installer only supports CMU firmware V74.00.324.\nDetected version: ${CMU_VER}\nInstallation aborted.\nYou can remove the USB drive.\nRebooting in 5 seconds..." \
    --no-cancel &
  sleep 5
  killall -q jci-dialog
  exit 1
fi

mkdir -p "${MYDIR}/logs"

show_failure()
{
  MESSAGE=$1
  echo "ERROR: ${MESSAGE}"
  sync
  killall -q jci-dialog
  /jci/tools/jci-dialog --info --title="HUD Settings Europe Region" \
    --text="${MESSAGE}\nDo not remove the USB drive.\nReview logs/${LOG_NAME}.log." --no-cancel &
  exit 1
}

# --- Prompt user: Install or Uninstall ---
/jci/tools/jci-dialog --question \
  --title="HUD Settings Europe Region" \
  --text="What would you like to do?" \
  --ok-label="Install" \
  --cancel-label="Uninstall"
CHOICE=$?

SYSTEM_APP="/jci/gui/apps/vehsettings/js/vehsettingsApp.js"
SYSTEM_APP_BACKUP="${SYSTEM_APP}.org"

if [ $CHOICE -eq 0 ]
then
  # ============================================================
  # INSTALL
  # ============================================================
  LOG_NAME=install
  exec > "${MYDIR}/logs/${LOG_NAME}.log" 2>&1
  echo "=== HUD Settings Europe Region mod install start ==="

  /jci/tools/jci-dialog --info --title="HUD Settings Europe Region" --text="Installing HUD Settings Europe Region mod...\nDo not remove USB drive." --no-cancel &

  # --- Backup and install vehsettingsApp.js ---
  MOD_APP="${MYDIR}/jci-mods/vehsettingsApp.js"
  if [ ! -f "${MOD_APP}" ]
  then
    show_failure "Install failed: jci-mods/vehsettingsApp.js is missing."
  fi

  if [ ! -e "${SYSTEM_APP_BACKUP}" ]
  then
    if ! cp -a "${SYSTEM_APP}" "${SYSTEM_APP_BACKUP}" \
      || [ ! -f "${SYSTEM_APP_BACKUP}" ] \
      || ! cmp -s "${SYSTEM_APP}" "${SYSTEM_APP_BACKUP}"
    then
      show_failure "Install failed: could not create or verify the vehsettingsApp.js backup."
    fi
    echo "Backed up vehsettingsApp.js"
  else
    if [ ! -f "${SYSTEM_APP_BACKUP}" ]
    then
      show_failure "Install failed: the existing vehsettingsApp.js backup is not a regular file."
    fi
    echo "vehsettingsApp.js backup already exists"
  fi

  if ! cp "${MOD_APP}" "${SYSTEM_APP}" || ! cmp -s "${MOD_APP}" "${SYSTEM_APP}"
  then
    show_failure "Install failed: could not copy or verify vehsettingsApp.js."
  fi
  echo "Installed vehsettingsApp.js"

  sync
  echo "=== HUD Settings Europe Region mod install complete ==="

  killall -q jci-dialog
  /jci/tools/jci-dialog --info --title="HUD Settings Europe Region" --text="Installation complete!\nYou can remove the USB drive.\nRebooting in 5 seconds..." --no-cancel &

else
  # ============================================================
  # UNINSTALL
  # ============================================================
  LOG_NAME=uninstall
  exec > "${MYDIR}/logs/${LOG_NAME}.log" 2>&1
  echo "=== HUD Settings Europe Region mod uninstall start ==="

  /jci/tools/jci-dialog --info --title="HUD Settings Europe Region" --text="Uninstalling HUD Settings Europe Region mod...\nDo not remove USB drive." --no-cancel &

  # --- Restore vehsettingsApp.js ---
  if [ -e "${SYSTEM_APP_BACKUP}" ]
  then
    if ! cp -a "${SYSTEM_APP_BACKUP}" "${SYSTEM_APP}" \
      || ! cmp -s "${SYSTEM_APP_BACKUP}" "${SYSTEM_APP}"
    then
      show_failure "Uninstall failed: could not restore or verify vehsettingsApp.js from backup."
    fi
    if ! rm "${SYSTEM_APP_BACKUP}"
    then
      show_failure "Uninstall failed: restored vehsettingsApp.js, but could not remove its backup."
    fi
    echo "Restored vehsettingsApp.js from backup"
  else
    show_failure "Uninstall failed: vehsettingsApp.js backup was not found."
  fi

  sync
  echo "=== HUD Settings Europe Region mod uninstall complete ==="

  killall -q jci-dialog
  /jci/tools/jci-dialog --info --title="HUD Settings Europe Region" --text="Uninstall complete!\nYou can remove the USB drive.\nRebooting in 5 seconds..." --no-cancel &

fi

sleep 5
killall -q jci-dialog
reboot
exit 0
