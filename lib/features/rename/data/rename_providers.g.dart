// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rename_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(renameBatchRepository)
final renameBatchRepositoryProvider = RenameBatchRepositoryProvider._();

final class RenameBatchRepositoryProvider
    extends
        $FunctionalProvider<
          RenameBatchRepository,
          RenameBatchRepository,
          RenameBatchRepository
        >
    with $Provider<RenameBatchRepository> {
  RenameBatchRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'renameBatchRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$renameBatchRepositoryHash();

  @$internal
  @override
  $ProviderElement<RenameBatchRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  RenameBatchRepository create(Ref ref) {
    return renameBatchRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RenameBatchRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RenameBatchRepository>(value),
    );
  }
}

String _$renameBatchRepositoryHash() =>
    r'2425572f3a40b6abce76570c2fe5d2c803ec3223';

@ProviderFor(renameRunner)
final renameRunnerProvider = RenameRunnerProvider._();

final class RenameRunnerProvider
    extends $FunctionalProvider<RenameRunner, RenameRunner, RenameRunner>
    with $Provider<RenameRunner> {
  RenameRunnerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'renameRunnerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$renameRunnerHash();

  @$internal
  @override
  $ProviderElement<RenameRunner> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  RenameRunner create(Ref ref) {
    return renameRunner(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RenameRunner value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RenameRunner>(value),
    );
  }
}

String _$renameRunnerHash() => r'4b095ac8e7fecf9cb49f02e8e5e63b8ff7bcba90';

/// Files in the session's collecting batch (the "✎ N" pill).

@ProviderFor(renameBatchCount)
final renameBatchCountProvider = RenameBatchCountFamily._();

/// Files in the session's collecting batch (the "✎ N" pill).

final class RenameBatchCountProvider
    extends $FunctionalProvider<AsyncValue<int>, int, Stream<int>>
    with $FutureModifier<int>, $StreamProvider<int> {
  /// Files in the session's collecting batch (the "✎ N" pill).
  RenameBatchCountProvider._({
    required RenameBatchCountFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'renameBatchCountProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$renameBatchCountHash();

  @override
  String toString() {
    return r'renameBatchCountProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<int> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<int> create(Ref ref) {
    final argument = this.argument as int;
    return renameBatchCount(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is RenameBatchCountProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$renameBatchCountHash() => r'b129c6eb76e44ce43d1795a4790eb8c64cbae491';

/// Files in the session's collecting batch (the "✎ N" pill).

final class RenameBatchCountFamily extends $Family
    with $FunctionalFamilyOverride<Stream<int>, int> {
  RenameBatchCountFamily._()
    : super(
        retry: null,
        name: r'renameBatchCountProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Files in the session's collecting batch (the "✎ N" pill).

  RenameBatchCountProvider call(int sessionId) =>
      RenameBatchCountProvider._(argument: sessionId, from: this);

  @override
  String toString() => r'renameBatchCountProvider';
}

@ProviderFor(renamePlanner)
final renamePlannerProvider = RenamePlannerProvider._();

final class RenamePlannerProvider
    extends $FunctionalProvider<RenamePlanner, RenamePlanner, RenamePlanner>
    with $Provider<RenamePlanner> {
  RenamePlannerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'renamePlannerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$renamePlannerHash();

  @$internal
  @override
  $ProviderElement<RenamePlanner> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  RenamePlanner create(Ref ref) {
    return renamePlanner(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RenamePlanner value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RenamePlanner>(value),
    );
  }
}

String _$renamePlannerHash() => r'd07ad6c9c88383af35e558adea7b45d24bec32f5';
