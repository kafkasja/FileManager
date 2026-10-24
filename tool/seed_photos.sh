#!/usr/bin/env bash
# Seed the connected Android device/emulator with test photos (TASK-V1).
#
#   tool/seed_photos.sh [-n COUNT] [-s SRC_DIR] [-d DEVICE_DIR] [--span SECONDS] [--clean]
#
#   -n COUNT       images to create (default 10000)
#   -s SRC_DIR     host folder with .jpg/.jpeg/.png sources (cycled). Default:
#                  5 screenshots of the current screen (PNG, no EXIF date, so
#                  the spread modified times decide the order). JPEG sources
#                  keep their EXIF DateTimeOriginal: all copies of one source
#                  then share a "taken" date.
#   -d DEVICE_DIR  target folder (default /sdcard/DCIM/KfmSeed)
#   --span SECONDS spread modified times over the last SECONDS (default
#                  31536000 = 365 days). On a real phone use 3600 so the seed
#                  is newer than the owner's photos (top of the deck).
#   --clean        delete DEVICE_DIR and the staging folder, then rescan
#
# Needs adb (on PATH, or ADB=/path/to/adb.exe) and exactly one device, or
# ANDROID_SERIAL set (phone + emulator connected). Safe to re-run after a
# USB drop: same file names are overwritten, the copy runs under nohup.
set -euo pipefail
export MSYS_NO_PATHCONV=1  # Git Bash: keep /sdcard paths as they are

count=10000
src=""
dest="/sdcard/DCIM/KfmSeed"
stage="/data/local/tmp/kfm_seed"
clean=false
span=31536000
while [ $# -gt 0 ]; do
  case "$1" in
    -n) count="$2"; shift 2 ;;
    -s) src="$2"; shift 2 ;;
    -d) dest="$2"; shift 2 ;;
    --span) span="$2"; shift 2 ;;
    --clean) clean=true; shift ;;
    -h|--help) sed -n '2,24p' "$0"; exit 0 ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
done

case "$count" in ''|*[!0-9]*) echo "-n needs a number" >&2; exit 2 ;; esac
case "$span" in ''|*[!0-9]*) echo "--span needs a number" >&2; exit 2 ;; esac
ADB="${ADB:-adb}"
adb() { "$ADB" "$@"; }  # not on PATH by default: ADB=$LOCALAPPDATA/Android/Sdk/platform-tools/adb.exe
# Host paths for a Windows adb.exe (MSYS_NO_PATHCONV stops Git Bash from
# converting them itself).
host_path() { if command -v cygpath >/dev/null; then cygpath -w "$1"; else echo "$1"; fi; }
command -v "$ADB" >/dev/null || { echo "adb not found (set ADB)" >&2; exit 1; }
[ "$(adb get-state 2>/dev/null)" = "device" ] || { echo "no device connected" >&2; exit 1; }

media_count() {
  # Rows MediaStore has for DEVICE_DIR (/sdcard is /storage/emulated/0 in _data).
  local dir="${dest/#\/sdcard/\/storage\/emulated\/0}"
  adb shell "content query --uri content://media/external/images/media --projection _id --where \"_data LIKE '$dir/%'\"" \
    | tr -d '\r' | grep -c '^Row:' || true
}

rescan() {
  # API 29+: ask MediaProvider to scan the primary volume. If it isn't
  # allowed or doesn't exist, a reboot always triggers a full scan.
  adb shell "content call --uri content://media/ --method scan_volume --arg external_primary" >/dev/null 2>&1 || true
}

wait_boot() {
  adb wait-for-device
  until [ "$(adb shell getprop sys.boot_completed | tr -d '\r')" = "1" ]; do sleep 2; done
}

if $clean; then
  adb shell "rm -rf '$dest' '$stage'"
  rescan
  echo "removed $dest; MediaStore rows left: $(media_count)"
  exit 0
fi

adb shell "mkdir -p '$stage' '$dest'"
if [ -n "$src" ]; then
  shopt -s nullglob nocaseglob
  files=("$src"/*.jpg "$src"/*.jpeg "$src"/*.png)
  [ ${#files[@]} -gt 0 ] || { echo "no .jpg/.jpeg/.png in $src" >&2; exit 1; }
  for f in "${files[@]}"; do adb push "$(host_path "$f")" "$stage/" >/dev/null; done
else
  for i in 1 2 3 4 5; do adb shell screencap -p "$stage/src_$i.png"; done
fi
mapfile -t sources < <(adb shell "ls '$stage'" | tr -d '\r' | grep -iE '\.(jpe?g|png)$')
n=${#sources[@]}
[ "$n" -gt 0 ] || { echo "no sources on the device" >&2; exit 1; }

# One on-device script: copy + set the modified time (no per-file adb round trip;
# printf %()T formats dates without forking `date` 10,000 times).
script="$(mktemp)"
now=$(date +%s)
{
  echo "set -e"
  for ((i = 0; i < count; i++)); do
    s="${sources[$((i % n))]}"
    ext="${s##*.}"
    ts=$(( now - i * span / count ))
    printf -v stamp '%(%Y%m%d%H%M.%S)T' "$ts"
    printf "cp '%s/%s' '%s/KFM_%05d.%s' && touch -t %s '%s/KFM_%05d.%s'\n" \
      "$stage" "$s" "$dest" "$i" "$ext" "$stamp" "$dest" "$i" "$ext"
  done
  echo "touch '$stage/done'"
} > "$script"
adb shell "rm -f '$stage/done'"
adb push "$(host_path "$script")" "$stage/run.sh" >/dev/null
rm -f "$script"
echo "copying $count images on the device…"
# nohup: a USB drop doesn't kill the copy; poll for the marker and wait out reconnects.
adb shell "nohup sh '$stage/run.sh' > '$stage/run.log' 2>&1 &"
until [ "$(adb shell "[ -f '$stage/done' ] && echo y" 2>/dev/null | tr -d '\r')" = "y" ]; do
  sleep 5
  adb wait-for-device
done

rescan
sleep 5
got=$(media_count)
if [ "$got" -lt "$count" ]; then
  echo "MediaStore has $got/$count; rebooting to force a full scan…"
  adb reboot
  wait_boot
  sleep 20
  got=$(media_count)
fi
echo "done: $got/$count images indexed by MediaStore in $dest"
[ "$got" -ge "$count" ] || { echo "warning: MediaStore did not index everything" >&2; exit 3; }
