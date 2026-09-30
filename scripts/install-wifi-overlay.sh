#!/usr/bin/env bash
# Push the signed RRO into /vendor/overlay (needs Rooted debugging on), reboot, verify.
source "$(dirname "$0")/lib.sh"
apk="$ROOT/tools/overlay-build/TabbyWifiOverlay.apk"; [ -s "$apk" ] || { echo "build it first"; exit 1; }
adbs root >/dev/null 2>&1 || true; sleep 3; adbs wait-for-device
[ "$(adbs shell id -u | tr -d '\r')" = "0" ] || { echo "adb is not root: enable Rooted debugging in Developer options"; exit 1; }
say "push"
adbs push "$apk" /data/local/tmp/TabbyWifiOverlay.apk >/dev/null
adbs shell 'mount -o remount,rw / && cp /data/local/tmp/TabbyWifiOverlay.apk /vendor/overlay/TabbyWifiOverlay.apk && chmod 644 /vendor/overlay/TabbyWifiOverlay.apk && chcon u:object_r:vendor_overlay_file:s0 /vendor/overlay/TabbyWifiOverlay.apk && ls -laZ /vendor/overlay/ && mount -o remount,ro /'
say "reboot"
adbs reboot; sleep 5; adbs wait-for-device
t=0; while [ $t -lt 300 ]; do [ "$(adbs shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = "1" ] && break; sleep 5; t=$((t+5)); done
say "overlay state"
adbs shell 'cmd overlay list | grep -iE -B1 -A2 "tabby|wifi.resources"; cmd overlay lookup com.android.wifi.resources com.android.wifi.resources:bool/config_wifiSaeUpgradeEnabled'
