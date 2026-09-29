#!/usr/bin/env bash
# Rollback to stock BTU firmware via heimdall. Untested by design; check file names first.
source "$(dirname "$0")/lib.sh"
fw="$DL/stock"; mkdir -p "$fw"
zip="$(ls "$DL"/*T555*.zip 2>/dev/null | grep -v UNOFFICIAL | head -1)"; [ -n "$zip" ] || { echo "no stock zip in $DL"; exit 1; }
unzip -o -q "$zip" -d "$fw"
for t in "$fw"/*.tar.md5; do tar -xf "$t" -C "$fw"; done
ls "$fw"
say "Reboot to download mode (adb reboot download), then run:"
echo "$HEIMDALL flash --BOOT $fw/boot.img --RECOVERY $fw/recovery.img --SYSTEM $fw/system.img.ext4 --CACHE $fw/cache.img.ext4 --HIDDEN $fw/hidden.img.ext4 --MODEM $fw/NON-HLOS.bin --ABOOT $fw/aboot.mbn --SBL1 $fw/sbl1.mbn --RPM $fw/rpm.mbn --TZ $fw/tz.mbn"
echo "Partition names must match: $HEIMDALL print-pit (see downloads/pit.txt)"
