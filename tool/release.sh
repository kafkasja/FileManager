#!/usr/bin/env bash
# Build a signed KFM release APK + SHA256SUMS.txt (TASK-R1).
#
#   bash tool/release.sh [--skip-tests]
#
# Output: build/release/kfm-X.Y.Z-N.apk and build/release/SHA256SUMS.txt.
# Refuses to run without android/key.properties (a debug-signed APK must
# never be published). Never uploads, tags or commits anything.
# One universal APK for arm + arm64 (phones) + x86_64 (Intel/AMD Chromebooks,
# emulators). One file for every device beats a smaller phone-only APK.
set -euo pipefail
cd "$(dirname "$0")/.."

skip_tests=false
[ "${1:-}" = "--skip-tests" ] && skip_tests=true

die() { echo "release: $*" >&2; exit 1; }

[ -f android/key.properties ] || die "android/key.properties missing (see README.md -> Releasing a new version). Not building a debug-signed release."

version_line=$(grep -E '^version:' pubspec.yaml | head -1)
full=${version_line#version: }
full=${full//[[:space:]]/}
name=${full%%+*}
code=${full#*+}
[[ "$name" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || die "pubspec version '$full' is not X.Y.Z+N"
[[ "$code" =~ ^[0-9]+$ ]] || die "pubspec build number '$code' is not a number"

app_version=$(grep -oE "appVersion = '[^']+'" lib/app/app_info.dart | sed -E "s/appVersion = '([^']+)'/\1/")
[ "$app_version" = "$name" ] || die "lib/app/app_info.dart appVersion '$app_version' != pubspec '$name'"

# versionCode must go up for every APK that leaves the PC.
mkdir -p build/release
last=0
for f in build/release/kfm-*-*.apk; do
  [ -e "$f" ] || continue
  n=${f##*-}; n=${n%.apk}
  [[ "$n" =~ ^[0-9]+$ ]] && [ "$n" -gt "$last" ] && last=$n
done
if [ "$last" -ge "$code" ] && [ ! -e "build/release/kfm-$name-$code.apk" ]; then
  die "build number $code is not higher than the last release's $last"
fi
echo "release: KFM $name (versionCode $code; last built $last)"

if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
  echo "release: WARNING: git tree is dirty" >&2
fi

flutter analyze
if [ "$skip_tests" = false ]; then flutter test test/; fi
flutter build apk --release --target-platform android-arm,android-arm64,android-x64

out="build/release/kfm-$name-$code.apk"
cp build/app/outputs/flutter-apk/app-release.apk "$out"

# apksigner needs Java: fall back to Android Studio's bundled JBR.
if [ -z "${JAVA_HOME:-}" ] && ! command -v java >/dev/null 2>&1; then
  for j in "/c/Program Files/Android/Android Studio/jbr" "${PROGRAMFILES:-}/Android/Android Studio/jbr"; do
    [ -x "$j/bin/java" ] || [ -x "$j/bin/java.exe" ] && { export JAVA_HOME="$j"; break; }
  done
fi

sdk="${ANDROID_HOME:-${LOCALAPPDATA:-}/Android/Sdk}"
bt=$(ls -d "$sdk"/build-tools/* 2>/dev/null | sort -V | tail -1 || true)
apksigner="$bt/apksigner"
[ -e "$apksigner.bat" ] && apksigner="$apksigner.bat"
if [ -n "$bt" ] && [ -e "$apksigner" ]; then
  certs=$("$apksigner" verify --print-certs "$out" 2>&1) || die "apksigner verify failed: $certs"
  echo "$certs" | grep -E 'Signer #1 certificate (DN|SHA-256)' || die "apksigner printed no signer: $certs"
  if echo "$certs" | grep -q 'CN=Android Debug'; then
    die "APK is signed with the DEBUG key: do not publish"
  fi
else
  echo "release: WARNING: apksigner not found, signature not checked" >&2
fi

aapt2="$bt/aapt2"
if [ -e "$aapt2" ] || [ -e "$aapt2.exe" ]; then
  echo "release: permissions:"
  "$aapt2" dump permissions "$out" | grep -E 'uses-permission' | sed 's/^/  /'
fi

(cd build/release && sha256sum "kfm-$name-$code.apk" > SHA256SUMS.txt && cat SHA256SUMS.txt)
echo "release: done -> $out"
