#!/usr/bin/env bash
# Privacy customisation over adb. No root. Idempotent.
source "$(dirname "$0")/lib.sh"
need curl; need python3
apkdir="$DL/apks"; mkdir -p "$apkdir"
idx="$apkdir/index-v1.json"
if [ ! -s "$idx" ] || [ "$(find "$idx" -mmin +720)" ]; then
  say "Fetch F-Droid index"; curl -sL -o "$idx" https://f-droid.org/repo/index-v1.json
fi
fdroid_url() {
  python3 - "$idx" "$1" <<'PY'
import json,sys
idx=json.load(open(sys.argv[1])); pkg=sys.argv[2]
apps=idx["packages"].get(pkg,[])
# 32-bit tablet: take the newest build that is universal or ships armeabi-v7a
ok=[a for a in apps if not a.get("nativecode") or "armeabi-v7a" in a["nativecode"]]
print("https://f-droid.org/repo/"+ok[0]["apkName"] if ok else "")
PY
}
installed="$(adbs shell pm list packages | tr -d '\r')"
while read -r pkg; do
  case "$pkg" in ""|\#*) continue;; esac
  if grep -q "^package:$pkg$" <<<"$installed"; then echo "have    $pkg"; continue; fi
  url="$(fdroid_url "$pkg")"; [ -z "$url" ] && { echo "not on F-Droid: $pkg"; continue; }
  f="$apkdir/$pkg.apk"; [ -s "$f" ] || curl -sL -o "$f" "$url"
  say "install $pkg"; adbs install -r "$f" || echo "FAILED $pkg"
done < "$ROOT/scripts/apps.txt"
say "Private DNS (Quad9 until RethinkDNS takes over)"
adbs shell settings put global private_dns_mode hostname
adbs shell settings put global private_dns_specifier dns.quad9.net
say "Disable packages"
while read -r p; do [ -n "$p" ] && { adbs shell pm disable-user --user 0 "$p" </dev/null || true; }; done < "$ROOT/scripts/disable-packages.txt"
say "Location: device-only (GPS) until a non-Google network backend is chosen"
adbs shell settings put secure location_mode 1
say "Misc"
adbs shell settings put global send_action_app_error 0
adbs shell settings put global stay_on_while_plugged_in 0
say "done"
