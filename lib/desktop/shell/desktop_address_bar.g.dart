// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'desktop_address_bar.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Looks a typed path up on disk (replaced in tests).

@ProviderFor(desktopPathKind)
final desktopPathKindProvider = DesktopPathKindProvider._();

/// Looks a typed path up on disk (replaced in tests).

final class DesktopPathKindProvider
    extends $FunctionalProvider<PathKindOf, PathKindOf, PathKindOf>
    with $Provider<PathKindOf> {
  /// Looks a typed path up on disk (replaced in tests).
  DesktopPathKindProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'desktopPathKindProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$desktopPathKindHash();

  @$internal
  @override
  $ProviderElement<PathKindOf> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PathKindOf create(Ref ref) {
    return desktopPathKind(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PathKindOf value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PathKindOf>(value),
    );
  }
}

String _$desktopPathKindHash() => r'aeea36e94773f4af84dceb83b02924c7b6787738';

/// A file to select (and scroll to) once its folder is open: the address
/// bar with a file path, "Open file location". Browse takes it.

@ProviderFor(DesktopRevealRequest)
final desktopRevealRequestProvider = DesktopRevealRequestProvider._();

/// A file to select (and scroll to) once its folder is open: the address
/// bar with a file path, "Open file location". Browse takes it.
final class DesktopRevealRequestProvider
    extends $NotifierProvider<DesktopRevealRequest, String?> {
  /// A file to select (and scroll to) once its folder is open: the address
  /// bar with a file path, "Open file location". Browse takes it.
  DesktopRevealRequestProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'desktopRevealRequestProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$desktopRevealRequestHash();

  @$internal
  @override
  DesktopRevealRequest create() => DesktopRevealRequest();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$desktopRevealRequestHash() =>
    r'816ceee5872ac2161ce803190397bd81e21339ec';

/// A file to select (and scroll to) once its folder is open: the address
/// bar with a file path, "Open file location". Browse takes it.

abstract class _$DesktopRevealRequest extends $Notifier<String?> {
  String? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<String?, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String?, String?>,
              String?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Bumped by F5 / the refresh button; screens re-read their lists.

@ProviderFor(DesktopRefreshTick)
final desktopRefreshTickProvider = DesktopRefreshTickProvider._();

/// Bumped by F5 / the refresh button; screens re-read their lists.
final class DesktopRefreshTickProvider
    extends $NotifierProvider<DesktopRefreshTick, int> {
  /// Bumped by F5 / the refresh button; screens re-read their lists.
  DesktopRefreshTickProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'desktopRefreshTickProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$desktopRefreshTickHash();

  @$internal
  @override
  DesktopRefreshTick create() => DesktopRefreshTick();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$desktopRefreshTickHash() =>
    r'2191fa268880ec593531e20962b2cf072d69718a';

/// Bumped by F5 / the refresh button; screens re-read their lists.

abstract class _$DesktopRefreshTick extends $Notifier<int> {
  int build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<int, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int, int>,
              int,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// The environment `%VAR%` expands from (replaced in tests).

@ProviderFor(desktopEnvironment)
final desktopEnvironmentProvider = DesktopEnvironmentProvider._();

/// The environment `%VAR%` expands from (replaced in tests).

final class DesktopEnvironmentProvider
    extends
        $FunctionalProvider<
          Map<String, String>,
          Map<String, String>,
          Map<String, String>
        >
    with $Provider<Map<String, String>> {
  /// The environment `%VAR%` expands from (replaced in tests).
  DesktopEnvironmentProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'desktopEnvironmentProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$desktopEnvironmentHash();

  @$internal
  @override
  $ProviderElement<Map<String, String>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Map<String, String> create(Ref ref) {
    return desktopEnvironment(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, String>>(value),
    );
  }
}

String _$desktopEnvironmentHash() =>
    r'b3a6329a152c1aa86dfd540732d0361e9e04b66d';
