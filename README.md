# KFM — Kaf's File Manager

A fast, safe file and photo manager for Android, with Windows and iPhone versions to follow.

- Swipe through photos and videos to sort them: left = trash, right = keep, with undo.
- Nothing is deleted by accident: deletes happen in safe batches, and recent swipes can always be undone.
- Smooth with tens of thousands of photos.
- No ads, no account, works offline.

Simple by default, with more control available when you want it: custom swipe directions, move/copy/tag/favorite actions, batch rename, filters, presets and swipe stats.

## Status
Early development.

## Building
Requires Flutter (stable) and the Android SDK.

```
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```
