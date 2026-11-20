# KFM — Kaf's File Manager

A fast, safe file and photo manager for **Android phones**, **Chromebooks** and **Windows PCs**.

- Swipe through photos and videos to sort them: left = trash, right = keep, with undo.
- Nothing is deleted by accident: deletes happen in safe batches, and recent swipes can always be undone.
- Smooth with tens of thousands of photos.
- No ads, no account, works offline.

Simple by default, with more control available when you want it: custom swipe directions, move/copy/tag/favorite actions, batch rename, filters, presets and swipe stats.

KFM is free and in early development, so expect rough edges.

## Download

You don't need a GitHub account. Open the download page:

### **[github.com/kafkasja/FileManager/releases/latest](https://github.com/kafkasja/FileManager/releases/latest)**

Scroll down to the **Assets** list on that page and pick the file for your device:

| Your device | File to download |
|---|---|
| Android phone or tablet (Android 7 or newer) | `KFM-android-….apk` |
| Chromebook (one that can run Android apps) | `KFM-android-….apk` (the same file) |
| Windows PC (Windows 10 version 1809 or newer, or Windows 11; 64-bit) | `KFM-windows-x64-….zip` |

Ignore the other files: "Source code" is the app's code, not the app, and the `checksum` files are only for checking that a download isn't damaged.

If you don't see a file for your device, that version isn't out yet for it.

There's no iPhone or Mac version yet.

### Install on Android

1. Open the download page above **on your phone** (in Chrome or any browser) and tap the `.apk` file.
2. If Chrome warns that the file might be harmful, tap **Download anyway**.
3. When the download finishes, tap **Open**, or find it in your **Files** / **Downloads** app.
4. If your phone says it isn't allowed to install apps from this source, tap **Settings**, turn on **Allow from this source**, then go back.
5. Tap **Install**. If Google Play Protect warns about an unknown app, tap **More details → Install anyway**.
6. Open **KFM** and allow access to your photos when it asks.

KFM isn't on the Play Store yet, which is why your phone shows these warnings.

### Install on a Chromebook

This is the hardest install: Chromebooks don't install `.apk` files from the Files app, so you need the built-in Linux tools once. It takes about 10 minutes and you'll type three commands. If your Chromebook is managed by a school or work, these settings may be locked.

1. **Turn on Linux:** open **Settings → About ChromeOS → Developers → Linux development environment → Set up**, and follow the steps.
2. **Allow app installs:** in the same **Linux development environment** settings, open **Develop Android apps** and turn on **Enable ADB debugging**. The Chromebook restarts.
   (Note: turning this off again later resets the Chromebook, which erases its data.)
3. **Download the `.apk`** in Chrome. In the **Files** app, drag it from **Downloads** into **Linux files**.
4. Open the **Terminal** app and click **penguin** (that's your Linux). In the window that opens, type these lines one at a time, pressing Enter after each. Lots of text scrolling past is normal; if it asks "Do you want to continue?", type `y` and press Enter.
   ```
   sudo apt install -y adb
   adb connect arc
   adb install KFM-android-*.apk
   ```
   If a box pops up asking to **Allow USB debugging**, tick **Always allow** and click **Allow**, then type the last line again.
5. **KFM** now appears in your app launcher.

To update: delete the old `.apk` from **Linux files**, then repeat steps 3 and 4 with the newer file (only the `adb connect arc` and `adb install` lines).

### Install on Windows

1. Download the `.zip` file.
2. Right-click it in your **Downloads** folder and choose **Extract All…**, then **Extract**.
3. Open the new **KFM-windows-x64-…** folder (if there's a **KFM** folder inside, open that too) and double-click **KFM.exe**.
4. If Windows says "Windows protected your PC", click **More info → Run anyway**. (The app isn't signed by a paid certificate yet.)

If Windows instead says **Smart App Control blocked** KFM, it can't run on that PC yet: Smart App Control only allows signed apps, and KFM isn't signed yet. Turning Smart App Control off makes it work, but Windows can't turn it back on without a reinstall, so we don't recommend it.

Tip: right-click KFM.exe and choose **Show more options → Send to → Desktop (create shortcut)** to start it from your desktop.

### Updating

- **Android:** download the newer `.apk` and install it over the old one. Your sorting, tags and settings stay.
- **Chromebook:** see the update line under "Install on a Chromebook".
- **Windows:** extract the new zip and replace the old KFM folder. Your data is kept separately, so nothing is lost.

KFM can also tell you when a new version is out: turn it on in **Settings** (off by default, because KFM doesn't go online unless you allow it).

## For developers

Needs Flutter (stable), the Android SDK and Java 17.

```
flutter pub get
flutter analyze
flutter test test/
flutter build apk --debug
```

The APK lands in `build/app/outputs/flutter-apk/`; install it on a connected phone or emulator with `flutter install` (or `adb install <file>`). Windows: `flutter build windows`.

### Releasing a new version

GitHub builds the downloads by itself when a version tag is pushed (`.github/workflows/`).

One-time setup: create the Android release key (keep backups: without it no update can ever be installed over the app), then add these repository secrets under **Settings → Secrets and variables → Actions**:
`KFM_KEYSTORE_BASE64` (the `.jks` file as base64), `KFM_KEYSTORE_PASSWORD`, `KFM_KEY_ALIAS`, `KFM_KEY_PASSWORD`.
Without them the Android download isn't built; the Windows one still is.

Each release:
1. Raise `version:` in `pubspec.yaml` (`X.Y.Z+N`, `N` always goes up by one) and set `appVersion` (`X.Y.Z`) and `appBuildNumber` (`N`) in `lib/app/app_info.dart` to match.
2. Commit, then `git tag vX.Y.Z` and `git push origin main vX.Y.Z`.
3. Wait for both jobs under **Actions**; the files appear on the release page.

To add the Android file to a release that already exists: **Actions → Release (Android) → Run workflow**, tag `vX.Y.Z`.
