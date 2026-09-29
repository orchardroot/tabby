# /e/OS-R Flash and Privacy Setup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Tablet-touching tasks run inline in the main session (hardware in the loop); only downloads and research are delegated. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Flash /e/OS-R 1.20 (Android 11, microG) onto the SM-T555, prove the modem and mobile data on a Vodafone UK SIM, and apply a no-root privacy customisation layer, all scripted from the Mac.

**Architecture:** Every tablet action is a bash script in `scripts/` driven over adb or heimdall from macOS. Backups and logs land in gitignored directories. Results are recorded in `logs/test-results.md`. Nothing is done from the tablet's own UI except the setup wizard and TWRP confirmation taps.

**Tech Stack:** adb (platform-tools, already at /usr/local/bin/adb), Heimdall CLI built from source, TWRP 3.1.0-1, /e/OS-R 1.20 zip, F-Droid APKs, bash, python3 for hash checks.

**Spec:** `docs/superpowers/specs/2026-09-29-eos-r-flash-design.md`

## Global Constraints

- TWRP must be exactly 3.1.0-1, file `twrp_3.1.0-1_sm-t555_13317.tar`, MD5 `6c243bd95565529a770544badbb126ed`. No other version.
- ROM is `e-1.20-r-20240321-UNOFFICIAL-gt510lte.zip`, 853074046 bytes.
- No root, no Magisk. All customisation over adb.
- EFS (`mmcblk0p13`), modemst1 (`p14`), modemst2 (`p15`), modem (`p2`) are backed up before any wipe. Backups never leave `backup/` and are never committed.
- Partition map read from the device: boot p16, recovery p17, system p25, cache p26, userdata p28.
- adb serial `8d509ccb`. Region BTU. Carrier for tests: Vodafone UK (MCC 234, MNC 15).
- Every script is idempotent and safe to re-run.

---

### Task 1: Toolchain and artefacts

**Files:**
- Create: `downloads/MANIFEST.md` (written by the download agent)
- Create: `scripts/lib.sh`
- Create: `scripts/check-tools.sh`

**Interfaces:**
- Produces: `scripts/lib.sh` exporting `ROOT`, `DL`, `BK`, `LOGS`, `SERIAL`, `HEIMDALL`, and functions `need <cmd>`, `adbs` (adb with serial), `say <msg>`.

- [ ] **Step 1: Write `scripts/lib.sh`**

```bash
#!/usr/bin/env bash
# Shared paths and helpers for the gt510lte scripts.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DL="$ROOT/downloads"; BK="$ROOT/backup"; LOGS="$ROOT/logs"
SERIAL="8d509ccb"
HEIMDALL="${HEIMDALL:-$ROOT/tools/heimdall}"
TWRP_TAR="$DL/twrp_3.1.0-1_sm-t555_13317.tar"
TWRP_MD5="6c243bd95565529a770544badbb126ed"
ROM_ZIP="$DL/e-1.20-r-20240321-UNOFFICIAL-gt510lte.zip"
ROM_SIZE=853074046
mkdir -p "$BK" "$LOGS"
say()  { printf '\n==> %s\n' "$*"; }
need() { command -v "$1" >/dev/null 2>&1 || { echo "missing tool: $1" >&2; exit 1; }; }
adbs() { adb -s "$SERIAL" "$@"; }
```

- [ ] **Step 2: Write `scripts/check-tools.sh`**

```bash
#!/usr/bin/env bash
source "$(dirname "$0")/lib.sh"
need adb; need shasum; need md5
[ -x "$HEIMDALL" ] || { echo "heimdall not at $HEIMDALL"; exit 1; }
"$HEIMDALL" version
say "TWRP md5"; [ "$(md5 -q "$TWRP_TAR")" = "$TWRP_MD5" ] && echo OK || { echo BAD; exit 1; }
say "ROM size"; [ "$(stat -f %z "$ROM_ZIP")" = "$ROM_SIZE" ] && echo OK || { echo BAD; exit 1; }
say "adb"; adbs get-state
```

- [ ] **Step 3: Build heimdall into `tools/heimdall`** (copy from the scratchpad build; `tools/` is gitignored)

- [ ] **Step 4: Run `scripts/check-tools.sh`**, expect three OKs and `device`.

- [ ] **Step 5: Commit** `scripts/lib.sh scripts/check-tools.sh downloads/MANIFEST.md .gitignore`

### Task 2: Flash TWRP and back up EFS and modem partitions

**Files:**
- Create: `scripts/flash-twrp.sh`
- Create: `scripts/backup-modem.sh`

**Interfaces:**
- Produces: `backup/<date>/efs.img modemst1.img modemst2.img modem.img SHA256SUMS`, and the tablet booted into TWRP.

- [ ] **Step 1: Write `scripts/flash-twrp.sh`**

```bash
#!/usr/bin/env bash
source "$(dirname "$0")/lib.sh"
need tar
say "Extract recovery.img from TWRP tar"
tmp="$(mktemp -d)"; tar -xf "$TWRP_TAR" -C "$tmp"; ls -la "$tmp"
img="$(ls "$tmp"/recovery.img)"
say "Reboot tablet to download mode"
adbs reboot download || true
sleep 8
say "Heimdall detect"; "$HEIMDALL" detect
say "Flash RECOVERY, no reboot"
"$HEIMDALL" flash --RECOVERY "$img" --no-reboot
echo "Now hold Power until the screen goes dark, then hold Power+Home+VolUp to boot TWRP."
```

- [ ] **Step 2: Run it.** If heimdall reports `Custom binary blocked by FRP lock` the user must enable OEM unlocking in Developer options; stop and report.

- [ ] **Step 3: Write `scripts/backup-modem.sh`** (runs while in TWRP; adb in TWRP is root)

```bash
#!/usr/bin/env bash
source "$(dirname "$0")/lib.sh"
out="$BK/$(date +%F)"; mkdir -p "$out"
adbs wait-for-recovery 2>/dev/null || adbs wait-for-device
adbs shell 'ls -l /dev/block/bootdevice/by-name/ | grep -E " (efs|modemst1|modemst2|modem) "'
for p in efs modemst1 modemst2 modem; do
  say "dump $p"
  adbs exec-out "dd if=/dev/block/bootdevice/by-name/$p bs=1m 2>/dev/null" > "$out/$p.img"
  ls -l "$out/$p.img"
done
say "stock RIL libs"
adbs shell 'mount /system 2>/dev/null; ls /system/vendor/lib | grep -iE "ril|qmi|sec-ril"' | tee "$out/stock-ril-libs.txt"
mkdir -p "$out/vendor-lib"
adbs pull /system/vendor/lib/libsec-ril.so "$out/vendor-lib/" 2>/dev/null || true
adbs pull /system/lib/libsec-ril.so "$out/vendor-lib/" 2>/dev/null || true
(cd "$out" && shasum -a 256 *.img > SHA256SUMS && cat SHA256SUMS)
```

- [ ] **Step 4: Run it.** Expect efs.img about 14 MB, modemst1/2 about 2 MB each, modem about 60 MB, all non-zero. If any is zero bytes, stop.

- [ ] **Step 5: Commit** the two scripts (not the backups).

### Task 3: Wipe, sideload, first boot

**Files:**
- Create: `scripts/install-rom.sh`
- Create: `logs/firstboot.txt` (gitignored)

- [ ] **Step 1: Write `scripts/install-rom.sh`**

```bash
#!/usr/bin/env bash
source "$(dirname "$0")/lib.sh"
say "Verify ROM size"; [ "$(stat -f %z "$ROM_ZIP")" = "$ROM_SIZE" ] || exit 1
say "Wipe in TWRP"
adbs shell twrp wipe cache
adbs shell twrp wipe dalvik
adbs shell twrp wipe system
adbs shell twrp wipe data
say "Format data (ext4 recreate, kills encryption metadata)"
adbs shell 'umount /data 2>/dev/null; make_ext4fs /dev/block/bootdevice/by-name/userdata || mke2fs -t ext4 /dev/block/bootdevice/by-name/userdata'
say "Sideload"
adbs shell twrp sideload &
sleep 3
adbs sideload "$ROM_ZIP"
say "Reboot and capture first boot"
adbs reboot
adbs wait-for-device
adbs logcat -c || true
adbs logcat > "$LOGS/firstboot.txt" &
echo "logcat pid $!  (ctrl-c or kill when setup wizard shows)"
```

- [ ] **Step 2: Run it.** Watch the tablet. Boot animation more than 5 minutes means go back to TWRP and redo the wipe.

- [ ] **Step 3: Record** `adbs shell getprop ro.build.fingerprint` and `ro.build.version.release` into `logs/test-results.md` header.

- [ ] **Step 4: Commit** the script and `logs/test-results.md`.

### Task 4: Non-modem test pass

**Files:**
- Create: `scripts/test-basics.sh`
- Modify: `logs/test-results.md`

- [ ] **Step 1: Write `scripts/test-basics.sh`** collecting evidence over adb (Wi-Fi state, BT state, GPS provider list, sensors, camera ids, audio devices).

```bash
#!/usr/bin/env bash
source "$(dirname "$0")/lib.sh"
o="$LOGS/basics-$(date +%F-%H%M).txt"
{
echo "# wifi";     adbs shell dumpsys wifi | grep -E "Wi-Fi is|mNetworkInfo" | head -3
echo "# bt";       adbs shell settings get global bluetooth_on
echo "# gps";      adbs shell dumpsys location | grep -E "gps|Provider" | head -5
echo "# sensors";  adbs shell dumpsys sensorservice | grep -E "^\s+[0-9a-f]{2}\)" | head -12
echo "# cameras";  adbs shell dumpsys media.camera | grep -E "Camera [0-9]" | head -4
echo "# audio";    adbs shell dumpsys audio | grep -E "devices|STREAM_MUSIC" | head -4
echo "# battery";  adbs shell dumpsys battery | grep -E "level|temperature"
} | tee "$o"
```

- [ ] **Step 2: Run it,** then do the manual checks (speaker, jack, cameras, rotation) and record pass/fail per spec section 4 in `logs/test-results.md`.

- [ ] **Step 3: Commit.**

### Task 5: Modem and data test with Vodafone SIM

**Files:**
- Create: `scripts/test-modem.sh`
- Create: `scripts/apn-vodafone.sh`
- Modify: `logs/test-results.md`

- [ ] **Step 1: Write `scripts/test-modem.sh`** (SIM inserted, Wi-Fi off)

```bash
#!/usr/bin/env bash
source "$(dirname "$0")/lib.sh"
o="$LOGS/modem-$(date +%F-%H%M)"
adbs shell svc wifi disable
adbs logcat -c
adbs logcat -b radio -b main > "$o.logcat" &
lp=$!
say "SIM";  adbs shell getprop gsm.sim.state
say "Reg";  adbs shell getprop gsm.operator.alpha; adbs shell getprop gsm.network.type
say "APNs"; adbs shell content query --uri content://telephony/carriers/preferapn 2>/dev/null
adbs shell svc data enable
sleep 15
say "Data state"; adbs shell dumpsys telephony.registry | grep -E "mDataConnectionState|mDataActivity|mServiceState" | head -5
say "Routes"; adbs shell ip route
say "Fetch"; adbs shell 'curl -m 15 -sI http://connectivitycheck.gstatic.com/generate_204 2>/dev/null | head -1 || wget -q -O- http://detectportal.firefox.com/success.txt'
sleep 5; kill $lp
grep -ciE "RILJ|RIL_" "$o.logcat"
```

- [ ] **Step 2: Write `scripts/apn-vodafone.sh`** inserting the Vodafone UK APN via the telephony content provider (values from the APN research agent; MCC 234 MNC 15; use `content insert --uri content://telephony/carriers`).

- [ ] **Step 3: Run test-modem. If data fails, run apn-vodafone then test-modem again.** Record the outcome and the decisive logcat lines in `logs/test-results.md`.

- [ ] **Step 4: Overnight battery test:** note battery level, leave SIM in, screen off; next session compare and grep the logcat for repeating `rild` restarts.

- [ ] **Step 5: Commit** scripts and results.

### Task 6: Privacy customisation layer

**Files:**
- Create: `scripts/customise.sh`
- Create: `scripts/apps.txt` (one F-Droid package id per line)
- Create: `scripts/disable-packages.txt`

- [ ] **Step 1: Write `scripts/apps.txt`**

```
org.fdroid.fdroid
com.aurora.store
app.organicmaps
com.celzero.bravedns
org.mozilla.fennec_fdroid
org.torproject.torbrowser
org.torproject.android
com.android.gpstest.osmdroid
org.thoughtcrime.securesms
com.nextcloud.client
org.videolan.vlc
org.koreader.launcher
com.simplemobiletools.gallery.pro
de.danoeh.antennapod
org.schabi.newpipe
com.termux
org.kde.kdeconnect_tp
```

- [ ] **Step 2: Write `scripts/disable-packages.txt`** (filled after `pm list packages` on the booted ROM; candidates: `foundation.e.apps` if Aurora preferred, `foundation.e.drive`, `foundation.e.accountmanager`, `com.android.email` if unused, `foundation.e.pdfviewer` if replaced).

- [ ] **Step 3: Write `scripts/customise.sh`**

```bash
#!/usr/bin/env bash
source "$(dirname "$0")/lib.sh"
need curl; need python3
apkdir="$DL/apks"; mkdir -p "$apkdir"
fdroid_url() { # latest apk url for a package from the F-Droid index
  python3 - "$1" <<'PY'
import json,sys,urllib.request
pkg=sys.argv[1]
idx=json.load(urllib.request.urlopen("https://f-droid.org/repo/index-v1.json"))
apps=[a for a in idx["packages"].get(pkg,[])]
print("https://f-droid.org/repo/"+apps[0]["apkName"]) if apps else print("")
PY
}
while read -r pkg; do
  [ -z "$pkg" ] && continue
  if adbs shell pm list packages | grep -q "^package:$pkg$"; then echo "have $pkg"; continue; fi
  url="$(fdroid_url "$pkg")"; [ -z "$url" ] && { echo "not on F-Droid: $pkg"; continue; }
  f="$apkdir/$pkg.apk"; [ -s "$f" ] || curl -sL -o "$f" "$url"
  say "install $pkg"; adbs install -r "$f"
done < "$ROOT/scripts/apps.txt"
say "Private DNS"
adbs shell settings put global private_dns_mode hostname
adbs shell settings put global private_dns_specifier dns.quad9.net
say "Disable packages"
while read -r p; do [ -n "$p" ] && adbs shell pm disable-user --user 0 "$p"; done < "$ROOT/scripts/disable-packages.txt"
say "Location: keep GPS only until a non-Google NLP backend is chosen"
adbs shell settings put secure location_mode 1
say "Misc privacy"
adbs shell settings put global send_action_app_error 0
adbs shell settings put secure usage_stats_enabled 0 2>/dev/null || true
```

Notes: Tor Browser and Signal are not on F-Droid; the script prints "not on F-Droid" for them and they are installed from their own APKs (Signal from signal.org, Tor Browser from torproject.org, both verified by their published signatures) in Step 5. Orbot is on F-Droid via the Guardian Project repo; if the main index lacks it, add the Guardian repo in F-Droid on-device.

- [ ] **Step 4: Run customise.sh**, confirm each app launches, record in results.

- [ ] **Step 5: Install Signal and Tor Browser from vendor APKs**, verifying the signing certificate fingerprints published by each project before `adb install`.

- [ ] **Step 6: On-device: Organic Maps download UK and Albania; RethinkDNS set to always-on VPN with DoT.**

- [ ] **Step 7: Commit.**

### Task 7: Rollback script and README

**Files:**
- Create: `scripts/restore-stock.sh`
- Create: `README.md`

- [ ] **Step 1: Write `scripts/restore-stock.sh`** using the stock firmware file names from `downloads/MANIFEST.md`:

```bash
#!/usr/bin/env bash
source "$(dirname "$0")/lib.sh"
fw="$DL/stock"; mkdir -p "$fw"
zip="$(ls "$DL"/*T555XXU1C*.zip | head -1)"; unzip -o -q "$zip" -d "$fw"
for t in "$fw"/*.tar.md5; do tar -xf "$t" -C "$fw"; done
ls "$fw"
say "Reboot to download mode, then:"
echo "$HEIMDALL flash --BOOT $fw/boot.img --RECOVERY $fw/recovery.img --SYSTEM $fw/system.img.ext4 --CACHE $fw/cache.img.ext4 --HIDDEN $fw/hidden.img.ext4 --MODEM $fw/NON-HLOS.bin --ABOOT $fw/aboot.mbn --SBL1 $fw/sbl1.mbn --RPM $fw/rpm.mbn --TZ $fw/tz.mbn"
```
(Untested by design. Adjust names to what the tar actually contains.)

- [ ] **Step 2: Write README.md** in the user's usual wry first-person voice with the standard footer, describing the tablet, the goal, what worked, and how to use the scripts.

- [ ] **Step 3: Commit.**

## Self-review notes

Spec coverage: sections 1 to 7 map to tasks 1 to 7. Phase 2 stub is documentation only, covered by the spec. Placeholder scan: `disable-packages.txt` is intentionally filled after first boot because the package list is unknowable until the ROM runs; the candidates are listed. Type consistency: `adbs`, `say`, `need`, `$DL`, `$BK`, `$LOGS`, `$HEIMDALL` used identically across tasks.
