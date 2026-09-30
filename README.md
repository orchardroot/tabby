# gt510lte

A £5 Samsung Galaxy Tab A 9.7 LTE (SM-T555) from 2015, dragged into something resembling the present. Stock was Android 7.1.1 with a security patch from the summer of 2017, which is not a sentence a SOC lead wants to type about a device on his own Wi-Fi.

The aim is simple and slightly contradictory: a privacy-centric Android (no Google account, microG instead of Play Services) that still uses its own SIM for mobile data, mainly for maps. Every Android 13 build for this tablet has the modem switched off. The Android 11 build has it switched on. So Android 11 it is, for now.

## What's on it

| | |
|---|---|
| ROM | /e/OS-R 1.20 (Android 11, LineageOS 18.1 base), unofficial build by ronnz98 from blizzard4591's device tree |
| Recovery | TWRP 3.1.0-1, and only that version. Newer ones don't boot on this thing |
| Launcher | Trebuchet |
| Privacy | microG, RethinkDNS (firewall plus DNS over TLS), private DNS via Quad9 as a fallback, /e/ cloud bits disabled |
| Apps | F-Droid, Aurora Store, Organic Maps, Fennec, Tor Browser, Orbot, Signal, VLC, KOReader, NewPipe, AntennaPod, Termux, KDE Connect, Fossify Gallery and Files, GPSTest, Jellyfin, Tusky |
| Root | None. Everything below is done over adb |

## Layout

```
docs/superpowers/specs/   design spec (why these decisions)
docs/superpowers/plans/   step-by-step plan that was executed
docs/phase2-ril-port-notes.md   research for porting the modem fix to Android 13
downloads/MANIFEST.md     every artefact with source URL, size and hash
scripts/                  everything that touches the tablet
logs/test-results.md      what actually works
backup/                   EFS and modem partition dumps (never committed, never share)
```

## Scripts, in the order they were used

| Script | Does |
|---|---|
| `check-tools.sh` | verifies heimdall, TWRP MD5, ROM size, adb |
| `flash-twrp.sh` | reboots to download mode and flashes recovery with heimdall |
| `backup-modem.sh` | from TWRP, dumps EFS, modemst1, modemst2, modem and the stock RIL libs. Do this before any wipe. The IMEI lives here and cannot be re-downloaded |
| `install-rom.sh` | wipes, formats data, sideloads the ROM, starts a first-boot logcat |
| `test-basics.sh` | Wi-Fi, BT, GPS, sensors, cameras, audio, battery over adb |
| `test-modem.sh` | SIM state, registration, APNs, data call, routes, a real fetch, radio logcat |
| `apn-vodafone.sh` | inserts the Vodafone UK APN if the ROM doesn't provision it |
| `customise.sh` | installs `apps.txt` from F-Droid (32-bit builds only), sets private DNS, disables `disable-packages.txt` |
| `vendor-apks.sh` | Signal, Tor Browser, Orbot, KOReader from their own hosts |
| `restore-stock.sh` | the way back to stock BTU firmware. Untested by design |

## Things that bit me

- **The installer's device check fails on TWRP 3.1.0.** Once /system is wiped there's no build.prop for the updater's legacy property environment, so `ro.product.device` reads empty and the zip aborts with `E3004: this device is .`. The fix is the `_nocheck` zip: same file, assert removed. Check your device name yourself first.
- **Heimdall isn't in Homebrew any more.** Built from source; it needs `-DCMAKE_POLICY_VERSION_MINIMUM=3.5`, the `#define nullptr 0` shim removed from two headers, and CoreFoundation and IOKit linked in. The binary lives in `tools/`, gitignored.
- **This is a 32-bit tablet.** F-Droid's index lists arm64 builds first. Filter on `nativecode` or you get `INSTALL_FAILED_NO_MATCHING_ABIS` and wonder why.
- **`adb shell` eats stdin.** A `while read` loop that calls adb shell disables exactly one package. Redirect `</dev/null`.
- **SourceForge is slow from here.** Four parallel byte-range requests got the 850 MB ROM in a quarter of the time.

## Known limitations of this build

SELinux is permissive. Front camera photo mode is reported flaky upstream. Mobile data on this device tree has mixed reports; see `logs/test-results.md` for what happened on my SIM. Phase 2, if it happens, is porting the modem fix onto the Android 13 tree, and the notes for that are in `docs/`.

## Rollback

`downloads/` holds the stock BTU T555XXU1CRG1 firmware, hashed in the manifest. `scripts/restore-stock.sh` prints the heimdall command. Knox is tripped regardless; nothing on this tablet ever needed Knox.

*orchardroot — made in Cheshire, under the supervision of two cats, one of whom sat on the tablet during the sideload.*
