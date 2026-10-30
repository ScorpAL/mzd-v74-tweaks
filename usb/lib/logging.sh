#!/bin/sh
# Literal configuration only: never source/eval data from USB.
mzd_logging_config() {
    MZD_LOG_LEVEL=debug
    if [ -e "$HERE/installer.conf" ] || [ -L "$HERE/installer.conf" ]; then
        [ -f "$HERE/installer.conf" ] && [ ! -L "$HERE/installer.conf" ] || return 1
        MZD_LOG_LEVEL=$(awk '
          {sub(/\r$/, "")}
          /^[[:space:]]*($|#)/ {next}
          /^logging=(normal|debug|off)$/ {if (++seen>1) bad=1; value=substr($0,9); next}
          {bad=1}
          END {if (bad) exit 1; print seen ? value : "debug"}
        ' "$HERE/installer.conf") || return 1
    fi
    export MZD_LOG_LEVEL
}
