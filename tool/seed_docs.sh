#!/usr/bin/env bash
# Seed the connected Android device/emulator with small documents (TASK-E4
# perf harness, Browse → Documents).
#
#   tool/seed_docs.sh [-n COUNT] [-d DEVICE_DIR] [--clean]
#
#   -n COUNT       files to create (default 3000), alternating .txt and .pdf
#                  (the .pdf files are plain text: only the name and size matter)
#   -d DEVICE_DIR  target folder (default /sdcard/Download/KfmPerfDocs)
#   --clean        delete DEVICE_DIR, then rescan
#
# KFM only sees non-media files with All files access:
#   adb shell appops set com.kaf.kfm MANAGE_EXTERNAL_STORAGE allow
# Needs adb (on PATH, or ADB=/path/to/adb.exe) and one device, or
# ANDROID_SERIAL set.
set -euo pipefail
export MSYS_NO_PATHCONV=1  # Git Bash: keep /sdcard paths as they are

count=3000
dest="/sdcard/Download/KfmPerfDocs"
clean=false
while [ $# -gt 0 ]; do
  case "$1" in
    -n) count="$2"; shift 2 ;;
    -d) dest="$2"; shift 2 ;;
    --clean) clean=true; shift ;;
    -h|--help) sed -n '2,15p' "$0"; exit 0 ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
done
case "$count" in ''|*[!0-9]*) echo "-n needs a number" >&2; exit 2 ;; esac
ADB="${ADB:-adb}"
adb() { "$ADB" "$@"; }
command -v "$ADB" >/dev/null || { echo "adb not found (set ADB)" >&2; exit 1; }
[ "$(adb get-state 2>/dev/null)" = "device" ] || { echo "no device connected" >&2; exit 1; }

rescan() {
  adb shell "content call --uri content://media --method scan_volume --arg external_primary" >/dev/null 2>&1 \
    || adb shell "am broadcast -a android.intent.action.MEDIA_MOUNTED -d file:///sdcard" >/dev/null 2>&1 || true
}

if $clean; then
  adb shell "rm -rf '$dest'"
  rescan
  echo "removed $dest"
  exit 0
fi

# One shell loop on the device (one adb round trip, not one per file).
adb shell "mkdir -p '$dest' && i=0; while [ \$i -lt $count ]; do \
  if [ \$((i % 2)) -eq 0 ]; then ext=txt; else ext=pdf; fi; \
  echo \"KFM perf document \$i\" > '$dest'/doc_\$(printf %05d \$i).\$ext; \
  touch -d @\$((\$(date +%s) - i * 60)) '$dest'/doc_\$(printf %05d \$i).\$ext 2>/dev/null; \
  i=\$((i + 1)); done"
rescan
echo "seeded $count documents in $dest"
