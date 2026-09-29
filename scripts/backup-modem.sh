#!/usr/bin/env bash
# Run while the tablet is in TWRP (adb is root there).
source "$(dirname "$0")/lib.sh"
out="$BK/$(date +%F)"; mkdir -p "$out"
adbs wait-for-recovery
say "by-name check"
adbs shell 'ls -l /dev/block/bootdevice/by-name/ | grep -E " (efs|modemst1|modemst2|modem) "'
for p in efs modemst1 modemst2 modem; do
  say "dump $p"
  adbs exec-out "dd if=/dev/block/bootdevice/by-name/$p bs=1048576 2>/dev/null" > "$out/$p.img"
  ls -l "$out/$p.img"
  [ -s "$out/$p.img" ] || { echo "EMPTY dump for $p, stopping"; exit 1; }
done
say "stock RIL libs"
adbs shell 'mount /system 2>/dev/null; ls /system/vendor/lib /system/lib 2>/dev/null | grep -iE "ril|qmi" | sort -u' | tee "$out/stock-ril-libs.txt"
mkdir -p "$out/vendor-lib"
for f in /system/vendor/lib/libsec-ril.so /system/lib/libsec-ril.so /system/lib/libril.so /system/vendor/lib/libril-qc-qmi-1.so; do
  adbs pull "$f" "$out/vendor-lib/" 2>/dev/null || true
done
adbs shell 'cat /system/build.prop' > "$out/stock-build.prop" 2>/dev/null || true
(cd "$out" && shasum -a 256 *.img > SHA256SUMS && cat SHA256SUMS)
