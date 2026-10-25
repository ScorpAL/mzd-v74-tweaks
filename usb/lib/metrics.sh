#!/bin/sh
# Read-only snapshots. CPU deltas are held by the browser, never written to USB.
mzd_metrics() {
    [ "$#" = 2 ] || return 1
    for value in "$@"; do
        case "$value" in ''|*[!0-9]*) return 1 ;; esac
    done
    awk -v previous="$1" -v idle_before="$2" '
        /^cpu / {
            total=0; for (i=2;i<=9;i++) total+=$i
            idle=$5+$6; delta=total-previous; rest=idle-idle_before
            percent="-"
            if (previous>0 && delta>0 && rest>=0 && rest<=delta) percent=sprintf("%.0f",100*(delta-rest)/delta)
            printf "cpu\t%.0f\t%.0f\t%s\n",total,idle,percent
            found=1; exit
        }
        END {if (!found) exit 1}
    ' /proc/stat || return 1
    # The header only needs system and resources space.
    # df -P avoids wrapped device names; escaped spaces stay inside one field.
    filesystems=$(df -Pk) || return 1
    printf '%s\n' "$filesystems" | awk '
        NR>1 && ($6=="/" || $6=="/tmp/mnt/resources" || $6=="/mnt/resources") && $2>0 && !seen[$6]++ {
            free=100*$4/$2; if(free<0)free=0; if(free>100)free=100
            printf "disk\t%s\t%.0f\n",$6,free
        }
    '
}
