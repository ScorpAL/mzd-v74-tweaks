#!/bin/sh

/jci/tools/jci-dialog --question \
  --title="JCI Backup" \
  --text="Create a full ZIP backup of JCI directory.\nAt least 170 MB of free space is required on the USB drive." \
  --ok-label="Start" \
  --cancel-label="Cancel"
CHOICE=$?

if [ "${CHOICE}" -ne 0 ]
then
  exit 0
fi

MYDIR=$(dirname "$(readlink -f "$0")")

show_error()
{
  MESSAGE=$1
  echo "ERROR: ${MESSAGE}" >&2
  killall -q jci-dialog
  /jci/tools/jci-dialog --info --title="JCI Backup" --text="${MESSAGE}"
}

confirm_without_space_check()
{
  MESSAGE=$1
  echo "WARNING: ${MESSAGE}" >&2
  /jci/tools/jci-dialog --question \
    --title="JCI Backup" \
    --text="${MESSAGE}\nFree space cannot be verified. Continue anyway?" \
    --ok-label="OK" \
    --cancel-label="Cancel"
}

DF_OUTPUT=$(df -Pk "${MYDIR}" 2>&1)
DF_STATUS=$?
if [ "${DF_STATUS}" -ne 0 ]
then
  echo "df failed with status ${DF_STATUS}: ${DF_OUTPUT}" >&2
  confirm_without_space_check "Unable to check free space on the USB drive."
  if [ "$?" -ne 0 ]
  then
    exit 0
  fi
else
  AVAILABLE_KB=$(printf '%s\n' "${DF_OUTPUT}" | awk 'NR == 2 { print $4 }')
  case "${AVAILABLE_KB}" in
    ''|*[!0-9]*)
      confirm_without_space_check "Unable to determine free space on the USB drive."
      if [ "$?" -ne 0 ]
      then
        exit 0
      fi
      ;;
    *)
      if [ "${AVAILABLE_KB}" -lt 174080 ]
      then
        show_error "At least 170 MB of free space is required on the USB drive."
        exit 1
      fi
      ;;
  esac
fi

if ! command -v zip >/dev/null 2>&1
then
  show_error "The zip utility is not available."
  exit 1
fi

get_cmu_sw_version()
{
  _ver=$(grep "^JCI_SW_VER=" /jci/version.ini | sed 's/^.*_\([^_]*\)\"$/\1/')
  _patch=$(grep "^JCI_SW_VER_PATCH=" /jci/version.ini | sed 's/^.*\"\([^\"]*\)\"$/\1/')
  _flavor=$(grep "^JCI_SW_FLAVOR=" /jci/version.ini | sed 's/^.*_\([^_]*\)\"$/\1/')

  if [ -n "${_flavor}" ]
  then
    echo "${_ver}${_patch}-${_flavor}"
  else
    echo "${_ver}${_patch}"
  fi
}

CMU_SW_VER=$(get_cmu_sw_version)
if [ -z "${CMU_SW_VER}" ]
then
  show_error "Unable to determine the CMU software version."
  exit 1
fi

if ! mkdir -p "${MYDIR}/logs"
then
  show_error "Unable to create the backup log directory on the USB drive."
  exit 1
fi

if ! touch "${MYDIR}/logs/backup.log"
then
  show_error "Unable to write to the USB drive."
  exit 1
fi
exec > "${MYDIR}/logs/backup.log" 2>&1

BACKUPZIP="${MYDIR}/JCI-${CMU_SW_VER}.zip"
ZIP_TMP="${BACKUPZIP}.tmp.$$"

echo "=== JCI backup start ==="
echo "Creating ${BACKUPZIP}"
/jci/tools/jci-dialog --info --title="JCI Backup" \
  --text="Creating a full ZIP backup of JCI...\nDo not remove the USB drive." --no-cancel &

zip -r "${ZIP_TMP}" /jci
ZIP_STATUS=$?
if [ "${ZIP_STATUS}" -ne 0 ]
then
  rm -f "${ZIP_TMP}"
  echo "ERROR: ZIP creation failed with status ${ZIP_STATUS}"
  killall -q jci-dialog
  /jci/tools/jci-dialog --info --title="JCI Backup" \
    --text="JCI backup failed.\nCheck logs/backup.log before removing the USB drive."
  exit 1
fi

if ! mv -f "${ZIP_TMP}" "${BACKUPZIP}"
then
  rm -f "${ZIP_TMP}"
  echo "ERROR: Failed to save ${BACKUPZIP}"
  killall -q jci-dialog
  /jci/tools/jci-dialog --info --title="JCI Backup" \
    --text="JCI backup failed while saving the ZIP file.\nCheck logs/backup.log before removing the USB drive."
  exit 1
fi

sync
echo "=== JCI backup complete ==="
killall -q jci-dialog
/jci/tools/jci-dialog --info --title="JCI Backup" \
  --text="JCI backup completed successfully.\nYou can remove the USB drive."
exit 0
