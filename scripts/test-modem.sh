#!/usr/bin/env bash
# SIM inserted. Turns Wi-Fi off, enables data, captures radio logcat.
source "$(dirname "$0")/lib.sh"
o="$LOGS/modem-$(date +%F-%H%M)"
adbs shell svc wifi disable
adbs logcat -c || true
adb -s "$SERIAL" logcat -b radio -b main > "$o.logcat" 2>&1 &
lp=$!
say "SIM";  adbs shell getprop gsm.sim.state
say "Reg";  adbs shell getprop gsm.operator.alpha; adbs shell getprop gsm.operator.numeric; adbs shell getprop gsm.network.type
say "Preferred APN"; adbs shell content query --uri content://telephony/carriers/preferapn 2>/dev/null || true
say "APNs for 23415"; adbs shell content query --uri content://telephony/carriers --where "'numeric=\"23415\"'" --projection name:apn:type:protocol 2>/dev/null || true
adbs shell svc data enable
sleep 20
say "Data state"; adbs shell dumpsys telephony.registry | grep -E "mDataConnectionState|mDataActivity|mServiceState|mDataNetworkType" | head -6
say "Routes"; adbs shell ip route
say "Interfaces"; adbs shell ip -o addr | grep -vE "lo |wlan"
say "Fetch"; adbs shell 'wget -q -T 15 -O - http://detectportal.firefox.com/success.txt 2>&1 | head -1'
say "Ping"; adbs shell 'ping -c 3 -W 5 9.9.9.9 2>&1 | tail -2'
sleep 3; kill $lp 2>/dev/null || true
say "RIL lines in log: $(grep -ciE 'RILJ|RIL_|rild' "$o.logcat")"
echo "log: $o.logcat"
