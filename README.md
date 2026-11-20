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
| Windows PC (Windows 10 or 11, 64-bit) | `KFM-windows-x64-….zip` |

Ignore the other files: "Source code" is the app's code, not the app, and the `checksum` file is only for checking that a download isn't damaged.

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

Chromebooks don't install `.apk` files from the Files app. You need the built-in Linux tools once. It takes about 10 minutes and you'll type three commands. If your Chromebook is managed by a school or work, these settings may be locked.

1. **Turn on Linux:** open **Settings → About ChromeOS → Developers → Linux development environment → Set up**, and follow the steps.
2. **Allow app installs:** in the same **Linux development environment** settings, open **Develop Android apps** and turn on **Enable ADB debugging**. The Chromebook restarts.
   (Note: turning this off again later resets the Chromebook, which erases its data.)
3. **Download the `.apk`** in Chrome. In the **Files** app, drag it from **Downloads** into **Linux files**.
4. Open the **Terminal** app, click **penguin**, and type these lines one at a time, pressing Enter after each:
   ```
   sudo apt install -y adb
   adb connect arc
   adb install KFM-android-*.apk
   ```
   If a box pops up asking to **Allow USB debugging**, tick **Always allow** and click **Allow**, then type the last line again.
5. **KFM** now appears in your app launcher.

To update, repeat steps 3 and 4 with the newer file (just the `adb connect arc` and `adb install` lines).

### Install on Windows

1. Download the `.zip` file.
2. Right-click it in your **Downloads** folder and choose **Extract All…**, then **Extract**.
3. Open the new **KFM** folder and double-click **KFM.exe**.
4. If Windows says "Windows protected your PC", click **More info → Run anyway**. (The app isn't signed by a paid certificate yet.)

Tip: right-click KFM.exe and choose **Show more options → Send to → Desktop (create shortcut)** to start it from your desktop.

### Updating

- **Android:** download the newer `.apk` and install it over the old one. Your sorting, tags and settings stay.
- **Windows:** extract the new zip and replace the old KFM folder. Your data is kept separately, so nothing is lost.

KFM can also tell you when a new version is out: turn it on in **Settings** (off by default, because KFM doesn't go online unless you allow it).

## For developers

Requires Flutter (stable) and the Android SDK.

```
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

Releases are built automatically by GitHub Actions when a version tag (`v1.2.3`) is pushed: see `.github/workflows/`.
