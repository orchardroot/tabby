#!/usr/bin/env bash
# Device identity: what the tablet calls itself, and how the shell greets you.
# Needs Rooted debugging for the Termux part. Idempotent.
source "$(dirname "$0")/lib.sh"
NAME="${NAME:-CATS}"
say "device and Bluetooth name: $NAME"
adbs shell settings put global device_name "$NAME" </dev/null
adbs shell settings put secure bluetooth_name "$NAME" </dev/null
say "Termux greeting"
adbs root >/dev/null 2>&1 || true; sleep 3; adbs wait-for-device
prefix=/data/data/com.termux/files/usr
if ! adbs shell "test -d $prefix/etc" </dev/null; then
  echo "Termux prefix missing; launching Termux once so it extracts its bootstrap"
  adbs shell am start -n com.termux/.app.TermuxActivity </dev/null >/dev/null
  for i in $(seq 1 12); do sleep 5; adbs shell "test -d $prefix/etc" </dev/null && break; done
fi
adbs shell "test -d $prefix/etc" </dev/null || { echo "Termux still not bootstrapped; open it once by hand and rerun"; exit 1; }
adbs shell "cat > $prefix/etc/motd" <<'MOTD'

  In A.D. 2101, war was beginning.

  CATS: How are you gentlemen !!
  CATS: All your base are belong to us.
  CATS: You have no chance to survive make your time.

  Captain: Move 'ZIG'. For great justice.

MOTD
adbs shell "chown \$(stat -c %u $prefix/etc) \$(stat -c %u $prefix/etc) $prefix/etc/motd 2>/dev/null; chmod 644 $prefix/etc/motd; rm -f /data/data/com.termux/files/home/.hushlogin; cat $prefix/etc/motd" </dev/null
