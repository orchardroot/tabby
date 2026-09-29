# Galaxy Tab A 9.7 LTE (SM-T555, gt510lte): privacy Android with working data

Date: 2026-09-29
Status: approved design, phase 1

## Goal

Turn a £5 SM-T555 into a privacy-centric Android tablet whose own SIM provides
mobile data, primarily for maps. No Google account, microG instead of Play
Services.

## Decisions already made

- Modem in the tablet is a hard requirement. Tethering from the phone is not an
  acceptable substitute.
- Privacy flavour: microG, no Google account. Aurora Store for Play apps,
  F-Droid for open source.
- Approach C: flash /e/OS-R (Android 11) now because it is the only modern
  build with modem code; treat an Android 13 port with the modem fix as a
  separate later project (phase 2).
- No root. Every customisation is done over adb without Magisk.

## Device facts (read over adb on 2026-09-29)

| Item | Value |
|---|---|
| Model | SM-T555, codename gt510lte, product gt510ltexx |
| SoC | Qualcomm MSM8916, 4x A53 1.2 GHz, 32-bit userspace |
| RAM / storage | 2 GB / 16 GB, microSD slot |
| Stock firmware | T555XXU1CQJ5, Android 7.1.1, patch 2017-08-01, region BTU (UK unbranded) |
| Knox warranty bit | 0 (never flashed) |
| SIM at time of writing | none inserted |
| adb serial | 8d509ccb |

## Build landscape (researched 2026-09-29)

| Build | Android | Modem |
|---|---|---|
| LineageOS 16.0 (VirsysElectron, 2019) | 9 | SIM not working |
| LineageOS 18.1 (blizzard4591, June 2021) | 11 | Developer got RIL working. Users confirm calls and SMS. Two users report mobile data shows signal but never transfers |
| /e/OS-R 1.20 (ronnz98, 2024-03-21) | 11 | Same 18.1 device tree, so same modem code. Data status unreported |
| LineageOS 20 (RGarrido03, 2024-01-05) | 13 | RIL non-functional, radio HAL not registered |
| /e/OS-T 3.2 (ronnz98, 2025-11-06) | 13 | Same tree as above, no modem |
| postmarketOS / Nura | Linux, mainline kernel | Data and SMS work, calls partial. Not Android, out of scope |

The 18.1 modem fix lives in blizzard4591's android_device_samsung_gt510lte
repo on the lineage-18.1 branch (April 2021 commits adding libsec-ril.so and a
klte-style radio setup). Phase 2 ports that forward.

## Phase 1 design

### 1. Repository

`~/Projects/gt510lte` holds:

- `docs/superpowers/specs/` this spec and later plans
- `downloads/MANIFEST.md` every artefact, its source URL, size and hash
- `downloads/` the artefacts themselves (gitignored)
- `scripts/` flash, backup, test and customisation scripts
- `logs/` logcats and test results (gitignored except summaries)
- `backup/` EFS and modem partition images (gitignored, never committed)

Every action against the tablet is a script in `scripts/`, run from the Mac.

### 2. Safety net

Done before any wipe, in this order:

1. Download stock BTU firmware for SM-T555 (T555XXU1CQJ5 or the newer
   T555XXU1CRG1) from SamMobile or SamFW. Record hash in the manifest.
2. Download TWRP 3.1.0-1 for SM-T555 (`twrp_3.1.0-1_sm-t555_13317.tar`) from
   the Google Drive re-upload in the XDA thread. Verify MD5
   `6c243bd95565529a770544badbb126ed`. No other TWRP version is acceptable.
3. Download `e-1.20-r-20240321-UNOFFICIAL-gt510lte.zip` from SourceForge
   (853,074,046 bytes). Record SHA-256.
4. Install heimdall via Homebrew (`heimdall-suite` cask). Confirm
   `heimdall detect` sees the tablet in download mode.
5. Flash TWRP only (recovery partition). Boot straight into TWRP.
6. From TWRP over adb, dump to `backup/`: the EFS partition (IMEI and modem
   calibration), the modem partition, and the stock `/system/vendor/lib`
   RIL libraries. Verify the dumps are non-empty and hash them.

Rationale: EFS cannot be re-downloaded. Stock modem blobs are phase 2 inputs.

### 3. Flash procedure

1. In TWRP: format data (type yes), wipe system, cache, dalvik.
2. `adb sideload` the /e/OS-R zip.
3. Reboot system. Start `adb logcat` the moment adb appears and keep it running
   until the setup wizard shows. Save as `logs/firstboot.txt`.
4. Setup wizard: skip the /e/ account, skip location services for now.
5. Confirm `adb devices` shows the tablet on the new build and record
   `ro.build.fingerprint`.

Stuck on the boot animation for more than 5 minutes means the format was
missed. Return to TWRP and repeat from step 1.

### 4. Test matrix

Run in this order, each recorded as pass, fail or partial in
`logs/test-results.md` with the relevant logcat excerpt.

Non-modem, no SIM needed:

- Wi-Fi on WPA2. Note the 18.1 report that mixed WPA2/WPA3 networks fail.
- Bluetooth pairing and audio.
- GPS: GPSTest from F-Droid, time to first fix outdoors.
- Speaker, headphone jack, microphone level.
- Rear and front camera, stills and video.
- Auto-rotate, brightness, physical keys.

Modem, SIM in (carrier to be confirmed by the user):

1. SIM detected: `getprop gsm.sim.state` reads READY.
2. Network registration: operator name appears.
3. SMS send and receive.
4. Voice call in and out (tablets can be odd here; partial is acceptable).
5. Mobile data: turn Wi-Fi off, load a page. Capture
   `adb logcat -b radio -b main` for the whole attempt.
6. If data fails: compare the APN list against the carrier's published
   settings, add the APN by hand, retry. Check IPv4 versus IPv6 APN protocol.
   Check `dumpsys telephony.registry` and `dumpsys connectivity` for a data
   call that connects but has no default route.
7. Overnight idle on battery with the SIM in, screen off. Report battery
   percentage drop and any repeating RIL crash in logcat. Catches a modem
   crash loop that would kill battery life.

The data outcome decides how urgent phase 2 is. It does not block phase 1
customisation.

### 5. Customisation layer

One script, `scripts/customise.sh`, idempotent, run over adb, no root. The
user edits the app and package lists before it runs.

Install (APKs fetched from F-Droid and verified against F-Droid's signing):

- F-Droid
- Aurora Store
- Organic Maps, then download UK and Albania offline packs
- RethinkDNS (firewall plus DNS over TLS, per-app blocking)
- GPSTest

Settings via adb:

- Private DNS set to a chosen resolver (default: the RethinkDNS one, since
  RethinkDNS handles it; otherwise Quad9).
- Disable /e/ cloud, account sync and telemetry components.
- microG: keep, but set the network location backend to a non-Google source
  (BeaconDB via the microG UnifiedNlp backend) and leave device registration
  off unless the user wants push notifications.
- Disable a package list of bundled apps the user does not want. Disable,
  not uninstall, so it is reversible.
- Developer options: keep USB debugging on, stay on the tablet's own adb key.

### 6. Rollback

`scripts/restore-stock.sh` documents the heimdall command sequence to reflash
the stock BTU firmware (BL, AP, CP, CSC) from download mode. Written and
checked against the firmware file names, run only if needed. Note: after a
custom ROM, stock 7.1.1 loses multi-user support; irrelevant here.

### 7. Phase 2 stub (not designed)

Inputs phase 2 will need, all produced by phase 1:

- Radio logcats from the data tests.
- Stock EFS, modem and RIL library backups.
- blizzard4591's lineage-18.1 gt510lte commits as the port source.
- RGarrido03's lineage-20 gt510lte tree as the port target.
- A GCP build VM (16 cores, 32 GB RAM, 400 GB disk) in the existing project.

Phase 2 gets its own brainstorm and spec once phase 1 results are in.

## Out of scope

- Root, Magisk, custom kernels.
- postmarketOS or any non-Android OS.
- Fixing camera or SELinux issues inherited from the 18.1 tree.
- Any change to the Pixel 4a.

## Risks

- Data may be genuinely broken on the 18.1 modem code, not just an APN
  issue. Then phase 1 delivers a calls-and-SMS tablet and phase 2 becomes
  the real project.
- The /e/OS-R build is a single unofficial build from March 2024 with one
  user report. It may not boot on this unit. Fallback is the LineageOS 18.1
  userdebug zip from June 2021 plus microG installed by hand.
- Download hosts for these files are fragile. Mirror every artefact into
  `downloads/` immediately and record hashes.
