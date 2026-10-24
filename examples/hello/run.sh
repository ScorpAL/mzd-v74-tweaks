#!/bin/sh
# A stateless command: uninstalled means ready to Run, not something to install.
set -u
ID=hello
FIRMWARE=74.00.324
REQUIRES=''
CONFLICTS=''
[ "$#" -le 1 ] || { printf 'Expected one action.\n' >&2; exit 1; }
case "${1:-}" in
    ''|-h|--help) printf 'Usage: sh run.sh <run|status>\n' ;;
    status)
        if [ ! -r /jci/version.ini ]; then printf 'Cannot read firmware version.\n' >&2; exit 1; fi
        if awk '$0 == "JCI_SW_VER=\"MAZ_CMU-150_74.00.324\"" {found=1} END {exit !found}' /jci/version.ini; then
            printf 'uninstalled\n'
        else
            printf 'unavailable\n'; printf 'Requires firmware 74.00.324.\n' >&2
        fi ;;
    run)
        state=$(sh "$0" status) || exit 1
        [ "$state" = uninstalled ] || exit 1
        printf 'Hello from the CMU shell!\n' ;;
    *) printf 'Unsupported action.\n' >&2; exit 1 ;;
esac
