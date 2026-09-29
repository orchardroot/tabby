#!/usr/bin/env bash
# Run while the tablet is in TWRP.
source "$(dirname "$0")/lib.sh"
say "Verify ROM size"; [ "$(stat -f %z "$ROM_ZIP")" = "$ROM_SIZE" ] || { echo "ROM size mismatch"; exit 1; }
adbs wait-for-recovery
say "Wipe in TWRP"
for p in cache dalvik system data; do adbs shell twrp wipe "$p"; done
say "Format userdata as ext4 (removes encryption footer)"
adbs shell 'umount /data 2>/dev/null; umount /sdcard 2>/dev/null; make_ext4fs /dev/block/bootdevice/by-name/userdata 2>&1 | tail -2 || mke2fs -t ext4 /dev/block/bootdevice/by-name/userdata 2>&1 | tail -2'
say "Sideload"
adbs shell twrp sideload &
sleep 4
adbs sideload "$ROM_ZIP"
say "Reboot and capture first boot"
adbs reboot || true
adbs wait-for-device
adbs logcat -c || true
nohup adb -s "$SERIAL" logcat > "$LOGS/firstboot.txt" 2>&1 &
echo "logcat pid $!  (kill when the setup wizard shows)"
