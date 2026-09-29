#!/usr/bin/env bash
source "$(dirname "$0")/lib.sh"
o="$LOGS/basics-$(date +%F-%H%M).txt"
{
echo "# build";    adbs shell getprop ro.build.fingerprint; adbs shell getprop ro.build.version.release
echo "# wifi";     adbs shell dumpsys wifi | grep -E "Wi-Fi is|mNetworkInfo|SSID" | head -3
echo "# bt";       adbs shell settings get global bluetooth_on
echo "# gps";      adbs shell dumpsys location | grep -iE "gps|provider" | head -6
echo "# sensors";  adbs shell dumpsys sensorservice | grep -E "^\s+[0-9a-f]{2}\)|Sensor List" | head -14
echo "# cameras";  adbs shell dumpsys media.camera | grep -iE "Camera [0-9]|Device [0-9]" | head -4
echo "# audio";    adbs shell dumpsys audio | grep -iE "devices|STREAM_MUSIC" | head -4
echo "# battery";  adbs shell dumpsys battery | grep -E "level|temperature|health"
echo "# selinux";  adbs shell getenforce
} | tee "$o"
