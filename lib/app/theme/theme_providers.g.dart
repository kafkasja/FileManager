// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'theme_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(themeMode)
final themeModeProvider = ThemeModeProvider._();

final class ThemeModeProvider
    extends
        $FunctionalProvider<AsyncValue<ThemeMode>, ThemeMode, Stream<ThemeMode>>
    with $FutureModifier<ThemeMode>, $StreamProvider<ThemeMode> {
  ThemeModeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'themeModeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$themeModeHash();

  @$internal
  @override
  $StreamProviderElement<ThemeMode> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<ThemeMode> create(Ref ref) {
    return themeMode(ref);
  }
}

String _$themeModeHash() => r'c8124ed8066d1a5144dfe6d92d2b4480ceb2f487';

/// Null = follow the system language.

@ProviderFor(appLocale)
final appLocaleProvider = AppLocaleProvider._();

/// Null = follow the system language.

final class AppLocaleProvider
    extends $FunctionalProvider<AsyncValue<Locale?>, Locale?, Stream<Locale?>>
    with $FutureModifier<Locale?>, $StreamProvider<Locale?> {
  /// Null = follow the system language.
  AppLocaleProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appLocaleProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appLocaleHash();

  @$internal
  @override
  $StreamProviderElement<Locale?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<Locale?> create(Ref ref) {
    return appLocale(ref);
  }
}

String _$appLocaleHash() => r'595cf2b60bdd59c9e6c773f2a41f0e46a1e31d1f';

/// L1 color theme (separate key from [themeMode]).

@ProviderFor(themeAccent)
final themeAccentProvider = ThemeAccentProvider._();

/// L1 color theme (separate key from [themeMode]).

final class ThemeAccentProvider
    extends
        $FunctionalProvider<AsyncValue<AppAccent>, AppAccent, Stream<AppAccent>>
    with $FutureModifier<AppAccent>, $StreamProvider<AppAccent> {
  /// L1 color theme (separate key from [themeMode]).
  ThemeAccentProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'themeAccentProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$themeAccentHash();

  @$internal
  @override
  $StreamProviderElement<AppAccent> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<AppAccent> create(Ref ref) {
    return themeAccent(ref);
  }
}

String _$themeAccentHash() => r'bea48c159fcd4a3a256dc4687ee7d57b31835ad1';

/// L1: the wallpaper's primary color on Android 12+, null elsewhere (older
/// Android, desktop, host tests). "System colors" is offered only when this
/// is non-null. The app re-reads it on resume, so a wallpaper change shows.

@ProviderFor(systemAccentSeed)
final systemAccentSeedProvider = SystemAccentSeedProvider._();

/// L1: the wallpaper's primary color on Android 12+, null elsewhere (older
/// Android, desktop, host tests). "System colors" is offered only when this
/// is non-null. The app re-reads it on resume, so a wallpaper change shows.

final class SystemAccentSeedProvider
    extends $FunctionalProvider<AsyncValue<Color?>, Color?, FutureOr<Color?>>
    with $FutureModifier<Color?>, $FutureProvider<Color?> {
  /// L1: the wallpaper's primary color on Android 12+, null elsewhere (older
  /// Android, desktop, host tests). "System colors" is offered only when this
  /// is non-null. The app re-reads it on resume, so a wallpaper change shows.
  SystemAccentSeedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'systemAccentSeedProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$systemAccentSeedHash();

  @$internal
  @override
  $FutureProviderElement<Color?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Color?> create(Ref ref) {
    return systemAccentSeed(ref);
  }
}

String _$systemAccentSeedHash() => r'cda6cacd95393c90e164eb92eac0892312fbfa48';
