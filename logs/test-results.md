# Test results

## Build (2026-09-29, first boot)

| | |
|---|---|
| Fingerprint | samsung/lineage_gt510lte/gt510lte:11/RQ3A.211001.001/eng.ronnz.20240321.101517:userdebug/test-keys |
| /e/OS | 1.20-r-20240321-UNOFFICIAL-gt510lte |
| Android | 11, security patch 2024-02-05 |
| SELinux | Permissive (known, inherited from the 18.1 tree) |
| Install | TWRP 3.1.0-1, nocheck zip via adb sideload, 270 s, RC=0 |
| First boot | reached setup wizard; user chose Trebuchet launcher |

## Non-modem (adb evidence, 2026-09-30)

| Item | Result | Evidence |
|---|---|---|
| Wi-Fi | radio up, not yet joined | dumpsys wifi: enabled, scanning |
| Bluetooth | on | bluetooth_on=1 |
| GPS | provider present, microG registered a listener | dumpsys location |
| Sensors | pass | K2HH accelerometer, CM3323 light, SX9500 grip all listed and running |
| Cameras | both devices enumerated | dumpsys media.camera: device 0 and 1 |
| Audio | speaker and earpiece devices present | dumpsys audio |
| Battery | 81%, health good, 25 C | dumpsys battery |
| First boot crashes | 1, media.codec (omx) | logs/firstboot.txt, cosmetic |
| SELinux | Permissive | getenforce |

Manual checks still to do by hand: speaker and headphone audio, camera capture, auto-rotate, brightness.

## Modem (Vodafone UK, MCC 234 MNC 15)

(pending SIM)
