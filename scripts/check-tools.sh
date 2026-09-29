#!/usr/bin/env bash
source "$(dirname "$0")/lib.sh"
need adb; need shasum; need md5
[ -x "$HEIMDALL" ] || { echo "heimdall not at $HEIMDALL"; exit 1; }
"$HEIMDALL" version
say "TWRP md5"; [ "$(md5 -q "$TWRP_TAR")" = "$TWRP_MD5" ] && echo OK || { echo BAD; exit 1; }
say "ROM size"; [ "$(stat -f %z "$ROM_ZIP")" = "$ROM_SIZE" ] && echo OK || { echo BAD; exit 1; }
say "adb"; adbs get-state
