#!/usr/bin/env bash
source "$(dirname "$0")/lib.sh"
need tar
[ "$(md5 -q "$TWRP_TAR")" = "$TWRP_MD5" ] || { echo "TWRP md5 mismatch, refusing"; exit 1; }
say "Extract recovery.img from TWRP tar"
tmp="$(mktemp -d)"; tar -xf "$TWRP_TAR" -C "$tmp"; ls -la "$tmp"
img="$tmp/recovery.img"; [ -s "$img" ] || { echo "no recovery.img in tar"; exit 1; }
say "Reboot tablet to download mode"
adbs reboot download || true
sleep 10
say "Heimdall detect"; "$HEIMDALL" detect
say "Flash RECOVERY (p17) and reboot"
"$HEIMDALL" flash --RECOVERY "$img"
echo "Tablet is rebooting. Run: adb wait-for-device && adb reboot recovery"
