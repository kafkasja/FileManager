import 'package:flutter/material.dart';
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
