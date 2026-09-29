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
