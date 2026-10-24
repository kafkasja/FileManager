// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'db_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(appDatabase)
final appDatabaseProvider = AppDatabaseProvider._();

final class AppDatabaseProvider
    extends $FunctionalProvider<AppDatabase, AppDatabase, AppDatabase>
    with $Provider<AppDatabase> {
  AppDatabaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appDatabaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appDatabaseHash();

  @$internal
  @override
  $ProviderElement<AppDatabase> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppDatabase create(Ref ref) {
    return appDatabase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppDatabase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppDatabase>(value),
    );
  }
}

String _$appDatabaseHash() => r'59cce38d45eeaba199eddd097d8e149d66f9f3e1';

@ProviderFor(dbWriteQueue)
final dbWriteQueueProvider = DbWriteQueueProvider._();

final class DbWriteQueueProvider
    extends $FunctionalProvider<DbWriteQueue, DbWriteQueue, DbWriteQueue>
    with $Provider<DbWriteQueue> {
  DbWriteQueueProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dbWriteQueueProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dbWriteQueueHash();

  @$internal
  @override
  $ProviderElement<DbWriteQueue> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DbWriteQueue create(Ref ref) {
    return dbWriteQueue(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DbWriteQueue value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DbWriteQueue>(value),
    );
  }
}

String _$dbWriteQueueHash() => r'020fa0517650da6a36cd81164797388df48291fb';

@ProviderFor(settingsRepository)
final settingsRepositoryProvider = SettingsRepositoryProvider._();

final class SettingsRepositoryProvider
    extends
        $FunctionalProvider<
          SettingsRepository,
          SettingsRepository,
          SettingsRepository
        >
    with $Provider<SettingsRepository> {
  SettingsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'settingsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$settingsRepositoryHash();

  @$internal
  @override
  $ProviderElement<SettingsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SettingsRepository create(Ref ref) {
    return settingsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SettingsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SettingsRepository>(value),
    );
  }
}

String _$settingsRepositoryHash() =>
    r'df0da6ac1620bad99e257456ed4f99ade521f4e0';

/// The F6 shell listens and shows a non-blocking "couldn't save" message.

@ProviderFor(dbWriteErrors)
final dbWriteErrorsProvider = DbWriteErrorsProvider._();

/// The F6 shell listens and shows a non-blocking "couldn't save" message.

final class DbWriteErrorsProvider
    extends
        $FunctionalProvider<
          AsyncValue<DbWriteError>,
          DbWriteError,
          Stream<DbWriteError>
        >
    with $FutureModifier<DbWriteError>, $StreamProvider<DbWriteError> {
  /// The F6 shell listens and shows a non-blocking "couldn't save" message.
  DbWriteErrorsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dbWriteErrorsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dbWriteErrorsHash();

  @$internal
  @override
  $StreamProviderElement<DbWriteError> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<DbWriteError> create(Ref ref) {
    return dbWriteErrors(ref);
  }
}

String _$dbWriteErrorsHash() => r'99785c62620c9fc6ae6176bbea946fb728d6ad7a';
