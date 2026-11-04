import 'package:flutter/widgets.dart';
import 'package:kfm/app/theme/theme_providers.dart';
import 'package:kfm/l10n/generated/app_localizations.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'notification_l10n.g.dart';

/// The supported locale KFM uses for [preferred] (the language setting, or
/// the system's when it follows the system): same language code, else
/// English.
Locale resolveAppLocale(Locale? preferred, Locale system) {
  final wanted = preferred ?? system;
  for (final l in AppLocalizations.supportedLocales) {
    if (l.languageCode == wanted.languageCode) return l;
  }
  return AppLocalizations.supportedLocales.first;
}

/// Texts outside the widget tree (notifications, tray, taskbar; TASK-X8)
/// in the language KFM shows: the setting `localeTag`, or the system
/// language when it is empty. Follows both: a switch re-renders whatever
/// listens.
@Riverpod(keepAlive: true)
class NotificationLocale extends _$NotificationLocale
    with WidgetsBindingObserver {
  @override
  Locale build() {
    final binding = WidgetsBinding.instance..addObserver(this);
    ref.onDispose(() => binding.removeObserver(this));
    return resolveAppLocale(
      ref.watch(appLocaleProvider).value,
      binding.platformDispatcher.locale,
    );
  }

  @override
  void didChangeLocales(List<Locale>? locales) => ref.invalidateSelf();
}

/// The strings of [NotificationLocale]'s language.
@Riverpod(keepAlive: true)
AppLocalizations notificationL10n(Ref ref) =>
    lookupAppLocalizations(ref.watch(notificationLocaleProvider));
