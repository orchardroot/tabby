#!/usr/bin/env bash
# Install branding/bootanimation/build/bootanimation.zip into /system/media (needs Rooted debugging).
source "$(dirname "$0")/lib.sh"
zip="$ROOT/branding/bootanimation/build/bootanimation.zip"; [ -s "$zip" ] || { echo "run branding/bootanimation/make.py first"; exit 1; }
adbs root >/dev/null 2>&1 || true; sleep 3; adbs wait-for-device
[ "$(adbs shell id -u | tr -d '\r')" = "0" ] || { echo "adb is not root: enable Rooted debugging"; exit 1; }
say "backup original"
mkdir -p "$BK/bootanimation"; [ -s "$BK/bootanimation/bootanimation-eos-original.zip" ] || adbs pull /system/media/bootanimation.zip "$BK/bootanimation/bootanimation-eos-original.zip"
say "install"
adbs push "$zip" /data/local/tmp/bootanimation.zip >/dev/null
adbs shell 'mount -o remount,rw / && cp /data/local/tmp/bootanimation.zip /system/media/bootanimation.zip && chmod 644 /system/media/bootanimation.zip && chcon u:object_r:system_file:s0 /system/media/bootanimation.zip && mount -o remount,ro / && ls -laZ /system/media/bootanimation.zip'
say "preview for 6 s"
adbs shell 'setprop service.bootanim.exit 0; logcat -c; (bootanimation >/dev/null 2>&1 &) ; sleep 6; setprop service.bootanim.exit 1; sleep 1; logcat -d -s BootAnimation:* | tail -5'
