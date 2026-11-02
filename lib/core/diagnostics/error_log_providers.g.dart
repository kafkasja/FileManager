// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'error_log_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// H5: the UI isolate's error log. `main` sets [ErrorLog.current] (and
/// overrides this); without it (tests) nothing is recorded.

@ProviderFor(errorLog)
final errorLogProvider = ErrorLogProvider._();

/// H5: the UI isolate's error log. `main` sets [ErrorLog.current] (and
/// overrides this); without it (tests) nothing is recorded.

final class ErrorLogProvider
    extends $FunctionalProvider<ErrorLog, ErrorLog, ErrorLog>
    with $Provider<ErrorLog> {
  /// H5: the UI isolate's error log. `main` sets [ErrorLog.current] (and
  /// overrides this); without it (tests) nothing is recorded.
  ErrorLogProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'errorLogProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$errorLogHash();

  @$internal
  @override
  $ProviderElement<ErrorLog> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ErrorLog create(Ref ref) {
    return errorLog(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ErrorLog value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ErrorLog>(value),
    );
  }
}

String _$errorLogHash() => r'5b8e358beb4b76824b8833b7ca3881a46f6eb4f9';

/// H5: failed queued writes go to the log too (the banner still shows
/// them). Watched in `App.build` (Riverpod 3 pauses unwatched providers).

@ProviderFor(errorLogDbBridge)
final errorLogDbBridgeProvider = ErrorLogDbBridgeProvider._();

/// H5: failed queued writes go to the log too (the banner still shows
/// them). Watched in `App.build` (Riverpod 3 pauses unwatched providers).

final class ErrorLogDbBridgeProvider
    extends $FunctionalProvider<void, void, void>
    with $Provider<void> {
  /// H5: failed queued writes go to the log too (the banner still shows
  /// them). Watched in `App.build` (Riverpod 3 pauses unwatched providers).
  ErrorLogDbBridgeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'errorLogDbBridgeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$errorLogDbBridgeHash();

  @$internal
  @override
  $ProviderElement<void> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  void create(Ref ref) {
    return errorLogDbBridge(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$errorLogDbBridgeHash() => r'e48d4ee91a724875da8ba7f4bb710453c15636e9';

/// Entries in the log, for Settings → About. Re-reads after every write or
/// clear (the Settings tab stays mounted, so a rebuild alone never comes).

@ProviderFor(errorLogCount)
final errorLogCountProvider = ErrorLogCountProvider._();

/// Entries in the log, for Settings → About. Re-reads after every write or
/// clear (the Settings tab stays mounted, so a rebuild alone never comes).

final class ErrorLogCountProvider
    extends $FunctionalProvider<AsyncValue<int>, int, FutureOr<int>>
    with $FutureModifier<int>, $FutureProvider<int> {
  /// Entries in the log, for Settings → About. Re-reads after every write or
  /// clear (the Settings tab stays mounted, so a rebuild alone never comes).
  ErrorLogCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'errorLogCountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$errorLogCountHash();

  @$internal
  @override
  $FutureProviderElement<int> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<int> create(Ref ref) {
    return errorLogCount(ref);
  }
}

String _$errorLogCountHash() => r'30e2f0ec52fc84dc9967dffe50c1d6a9b4bd2500';

/// Device facts for the export header (no serial, Android ID or account).

@ProviderFor(errorLogExportHeader)
final errorLogExportHeaderProvider = ErrorLogExportHeaderProvider._();

/// Device facts for the export header (no serial, Android ID or account).

final class ErrorLogExportHeaderProvider
    extends
        $FunctionalProvider<
          AsyncValue<ExportHeader>,
          ExportHeader,
          FutureOr<ExportHeader>
        >
    with $FutureModifier<ExportHeader>, $FutureProvider<ExportHeader> {
  /// Device facts for the export header (no serial, Android ID or account).
  ErrorLogExportHeaderProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'errorLogExportHeaderProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$errorLogExportHeaderHash();

  @$internal
  @override
  $FutureProviderElement<ExportHeader> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ExportHeader> create(Ref ref) {
    return errorLogExportHeader(ref);
  }
}

String _$errorLogExportHeaderHash() =>
    r'7a26d92ef4604e70a88d356493485e3cd5c76dc8';

@ProviderFor(errorLogSharer)
final errorLogSharerProvider = ErrorLogSharerProvider._();

final class ErrorLogSharerProvider
    extends $FunctionalProvider<ErrorLogSharer, ErrorLogSharer, ErrorLogSharer>
    with $Provider<ErrorLogSharer> {
  ErrorLogSharerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'errorLogSharerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$errorLogSharerHash();

  @$internal
  @override
  $ProviderElement<ErrorLogSharer> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ErrorLogSharer create(Ref ref) {
    return errorLogSharer(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ErrorLogSharer value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ErrorLogSharer>(value),
    );
  }
}

String _$errorLogSharerHash() => r'4ee7ee1cc6f1c4e3427e0eccdc5daa207cd6a8fa';
