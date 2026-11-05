import 'package:dynamic_color/dynamic_color.dart' show DynamicColorPlugin;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:kfm/app/theme/app_accent.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'theme_providers.g.dart';

ThemeMode themeModeFromSetting(String value) => ThemeMode.values.firstWhere(
  (m) => m.name == value,
  orElse: () => ThemeMode.system,
);

/// '' = follow the system; otherwise a BCP-47 tag like 'en' or 'pt-BR'.
Locale? localeFromTag(String tag) {
  if (tag.isEmpty) return null;
  final parts = tag.split('-');
  return Locale.fromSubtags(
    languageCode: parts.first,
    countryCode: parts.length > 1 ? parts[1] : null,
  );
}

/// E2 §7: Reduce motion (the app also honours the system setting).
@Riverpod(keepAlive: true)
Stream<bool> reduceMotion(Ref ref) =>
    ref.watch(settingsRepositoryProvider).watch(AppSettings.reduceMotion);

/// E2 §7: High contrast.
@Riverpod(keepAlive: true)
Stream<bool> highContrast(Ref ref) =>
    ref.watch(settingsRepositoryProvider).watch(AppSettings.highContrast);

@Riverpod(keepAlive: true)
Stream<ThemeMode> themeMode(Ref ref) => ref
    .watch(settingsRepositoryProvider)
    .watch(AppSettings.themeMode)
    .map(themeModeFromSetting);

/// Null = follow the system language.
@Riverpod(keepAlive: true)
Stream<Locale?> appLocale(Ref ref) => ref
    .watch(settingsRepositoryProvider)
    .watch(AppSettings.localeTag)
    .map(localeFromTag);

/// L1 color theme (separate key from [themeMode]).
@Riverpod(keepAlive: true)
Stream<AppAccent> themeAccent(Ref ref) =>
    ref.watch(settingsRepositoryProvider).watch(AppSettings.themeAccent);

/// L1: the wallpaper's primary color on Android 12+, null elsewhere (older
/// Android, desktop, host tests). "System colors" is offered only when this
/// is non-null. The app re-reads it on resume, so a wallpaper change shows.
@Riverpod(keepAlive: true)
Future<Color?> systemAccentSeed(Ref ref) async {
  try {
    final palette = await DynamicColorPlugin.getCorePalette();
    return palette == null ? null : Color(palette.primary.get(40));
  } on PlatformException {
    // "No wallpaper palette" is a normal answer here, not an error to show.
    return null;
  }
}
