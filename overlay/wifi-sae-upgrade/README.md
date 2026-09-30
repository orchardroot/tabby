# Wi-Fi SAE upgrade overlay

Runtime resource overlay for `com.android.wifi.resources` that sets
`config_wifiSaeUpgradeEnabled` and `config_wifiSaeUpgradeOffloadEnabled` to false.

Why: Android 11 rewrites a WPA2-PSK join to WPA3-SAE whenever the access point
advertises SAE (WPA2/WPA3 transition mode), and does not check whether the driver
can do SAE. The gt510lte driver cannot, so every join to a modern router fails with
`WPA: Failed to select authenticated key management type`. The supplicant debug line
that gives it away:

```
WPA: AP key_mgmt 0x402 network profile key_mgmt 0x400; available key_mgmt 0x0
```

Build: `scripts/build-wifi-overlay.sh` (needs `tools/env.sh` from an Android SDK
install and the AOSP test key `com.android.wifi.resources.{pk8,x509.pem}` in
`tools/keys/`, fetched from
`platform/frameworks/opt/net/wifi` at `android11-release`, `service/resources-certs/`).
The target package on this ROM is signed with that public test key, so the overlay
carries the same signature. The overlayable policy is `product|system|vendor`, so
placing it in `/vendor/overlay` is enough anyway.

Install: `scripts/install-wifi-overlay.sh` with Rooted debugging on. It remounts
/ read-write, copies the APK into `/vendor/overlay`, sets the SELinux label, reboots,
and prints the overlay state and the resulting flag value.
