// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_l10n.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Texts outside the widget tree (notifications, tray, taskbar; TASK-X8)
/// in the language KFM shows: the setting `localeTag`, or the system
/// language when it is empty. Follows both: a switch re-renders whatever
/// listens.

@ProviderFor(NotificationLocale)
final notificationLocaleProvider = NotificationLocaleProvider._();

/// Texts outside the widget tree (notifications, tray, taskbar; TASK-X8)
/// in the language KFM shows: the setting `localeTag`, or the system
/// language when it is empty. Follows both: a switch re-renders whatever
/// listens.
final class NotificationLocaleProvider
    extends $NotifierProvider<NotificationLocale, Locale> {
  /// Texts outside the widget tree (notifications, tray, taskbar; TASK-X8)
  /// in the language KFM shows: the setting `localeTag`, or the system
  /// language when it is empty. Follows both: a switch re-renders whatever
  /// listens.
  NotificationLocaleProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notificationLocaleProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notificationLocaleHash();

  @$internal
  @override
  NotificationLocale create() => NotificationLocale();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Locale value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Locale>(value),
    );
  }
}

String _$notificationLocaleHash() =>
    r'0eeac6793e9bd831ccf507f76a846188f4233b66';

/// Texts outside the widget tree (notifications, tray, taskbar; TASK-X8)
/// in the language KFM shows: the setting `localeTag`, or the system
/// language when it is empty. Follows both: a switch re-renders whatever
/// listens.

abstract class _$NotificationLocale extends $Notifier<Locale> {
  Locale build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<Locale, Locale>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Locale, Locale>,
              Locale,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// The strings of [NotificationLocale]'s language.

@ProviderFor(notificationL10n)
final notificationL10nProvider = NotificationL10nProvider._();

/// The strings of [NotificationLocale]'s language.

final class NotificationL10nProvider
    extends
        $FunctionalProvider<
          AppLocalizations,
          AppLocalizations,
          AppLocalizations
        >
    with $Provider<AppLocalizations> {
  /// The strings of [NotificationLocale]'s language.
  NotificationL10nProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notificationL10nProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notificationL10nHash();

  @$internal
  @override
  $ProviderElement<AppLocalizations> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppLocalizations create(Ref ref) {
    return notificationL10n(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppLocalizations value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppLocalizations>(value),
    );
  }
}

String _$notificationL10nHash() => r'e28d81f1d301f1a9c97eb9f2075dccb38f5116e2';
