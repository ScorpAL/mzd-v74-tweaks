#!/bin/sh
case "$1" in
status) printf 'uninstalled\n' ;;
run)
 if [ -n "${MZD_PROGRESS_FILE:-}" ]; then
   printf '0\n2\nSynthetic progress\n' > "$MZD_PROGRESS_FILE"
   sleep 1
   printf '2\n2\nSynthetic complete\n' > "$MZD_PROGRESS_FILE"
 fi
 printf 'Synthetic command completed; no vehicle changes.\n' ;;
*) exit 1 ;;
esac
