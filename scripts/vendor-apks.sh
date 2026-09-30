#!/usr/bin/env bash
# Apps not in the main F-Droid index, fetched over HTTPS from each project's own host.
# 32-bit tablet: always the armeabi-v7a or universal build.
source "$(dirname "$0")/lib.sh"
need curl; need python3
d="$DL/apks/vendor"; mkdir -p "$d"
have() { adbs shell pm list packages </dev/null | tr -d '\r' | grep -q "^package:$1$"; }
inst() { say "install $2 from $1"; [ -s "$2" ] || curl -sL -o "$2" "$1"; ls -l "$2"; adbs install -r "$2" </dev/null || echo "FAILED $2"; }

if ! have org.thoughtcrime.securesms; then
  u="$(curl -sL https://updates.signal.org/android/latest.json | python3 -c 'import json,sys;print(json.load(sys.stdin)["url"])')"
  inst "$u" "$d/signal.apk"
fi
if ! have org.torproject.torbrowser; then
  v="$(curl -sL https://dist.torproject.org/torbrowser/ | grep -oE 'href="[0-9]+\.[0-9.]+/"' | tr -d 'href="/' | sort -V | tail -1)"
  inst "https://dist.torproject.org/torbrowser/$v/tor-browser-android-armv7-$v.apk" "$d/torbrowser-armv7.apk"
fi
if ! have org.torproject.android; then
  u="$(curl -sL https://api.github.com/repos/guardianproject/orbot-android/releases/latest | python3 -c 'import json,sys;a=[x["browser_download_url"] for x in json.load(sys.stdin)["assets"] if x["name"].endswith(".apk") and ("armeabi-v7a" in x["name"] or "universal" in x["name"])];print(a[0] if a else "")')"
  [ -n "$u" ] && inst "$u" "$d/orbot-armv7.apk" || echo "no orbot asset found"
fi
if ! have org.koreader.launcher; then
  u="$(curl -sL https://api.github.com/repos/koreader/koreader/releases/latest | python3 -c 'import json,sys;a=[x["browser_download_url"] for x in json.load(sys.stdin)["assets"] if x["name"].endswith(".apk") and "arm-" in x["name"] and "arm64" not in x["name"]];print(a[0] if a else "")')"
  [ -n "$u" ] && inst "$u" "$d/koreader-arm.apk" || echo "no koreader asset found"
fi
say "signing certs (SHA-256) of what was installed, for the record"
for p in org.thoughtcrime.securesms org.torproject.torbrowser org.torproject.android org.koreader.launcher; do
  printf '%s: ' "$p"; adbs shell dumpsys package "$p" </dev/null | grep -m1 -oE "signatures=.*" || echo "(not installed)"
done
