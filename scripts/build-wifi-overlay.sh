#!/usr/bin/env bash
# Build and sign the Tabby Wi-Fi RRO that disables Android 11's WPA2-to-WPA3 SAE upgrade.
# Needs tools/env.sh (aapt2, apksigner, android.jar) and tools/keys/com.android.wifi.resources.{pk8,x509.pem}.
source "$(dirname "$0")/lib.sh"
source "$ROOT/tools/env.sh"
src="$ROOT/overlay/wifi-sae-upgrade"; out="$ROOT/tools/overlay-build"; rm -rf "$out"; mkdir -p "$out"
say "aapt2 compile"
"$AAPT2" compile --dir "$src/res" -o "$out/res.zip"
say "aapt2 link"
"$AAPT2" link -o "$out/unsigned.apk" --manifest "$src/AndroidManifest.xml" -I "$ANDROID_JAR" "$out/res.zip" --min-sdk-version 30 --target-sdk-version 30
say "sign with the ServiceWifiResources test key (same signer as the target package)"
"$APKSIGNER" sign --key "$KEYS_DIR/com.android.wifi.resources.pk8" --cert "$KEYS_DIR/com.android.wifi.resources.x509.pem" --v1-signing-enabled true --v2-signing-enabled true --out "$out/TabbyWifiOverlay.apk" "$out/unsigned.apk"
"$APKSIGNER" verify --print-certs "$out/TabbyWifiOverlay.apk" | head -3
say "dump"
"$AAPT2" dump overlayable "$ROOT/tools/target/ServiceWifiResources.apk" | grep -A3 -i "WifiCustomization" | head -6 || true
"$AAPT2" dump badging "$out/TabbyWifiOverlay.apk" | head -3
ls -l "$out/TabbyWifiOverlay.apk"
