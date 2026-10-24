// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(sessionRepository)
final sessionRepositoryProvider = SessionRepositoryProvider._();

final class SessionRepositoryProvider
    extends
        $FunctionalProvider<
          SessionRepository,
          SessionRepository,
          SessionRepository
        >
    with $Provider<SessionRepository> {
  SessionRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sessionRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sessionRepositoryHash();

  @$internal
  @override
  $ProviderElement<SessionRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SessionRepository create(Ref ref) {
    return sessionRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SessionRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SessionRepository>(value),
    );
  }
}

String _$sessionRepositoryHash() => r'74000152879bb1c571ff24884294a77cd9526f32';

/// Shared by undo (S2) and delete commits (D2).

@ProviderFor(historyLock)
final historyLockProvider = HistoryLockProvider._();

/// Shared by undo (S2) and delete commits (D2).

final class HistoryLockProvider
    extends $FunctionalProvider<SerialLock, SerialLock, SerialLock>
    with $Provider<SerialLock> {
  /// Shared by undo (S2) and delete commits (D2).
  HistoryLockProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'historyLockProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$historyLockHash();

  @$internal
  @override
  $ProviderElement<SerialLock> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SerialLock create(Ref ref) {
    return historyLock(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SerialLock value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SerialLock>(value),
    );
  }
}

String _$historyLockHash() => r'37681c36cc92e148ea4a166a3898081e69fe8da2';

@ProviderFor(undoRepository)
final undoRepositoryProvider = UndoRepositoryProvider._();

final class UndoRepositoryProvider
    extends $FunctionalProvider<UndoRepository, UndoRepository, UndoRepository>
    with $Provider<UndoRepository> {
  UndoRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'undoRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$undoRepositoryHash();

  @$internal
  @override
  $ProviderElement<UndoRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  UndoRepository create(Ref ref) {
    return undoRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UndoRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UndoRepository>(value),
    );
  }
}

String _$undoRepositoryHash() => r'2526e69a478dfb799eacadfbd509cc8478aaeb1e';

@ProviderFor(deleteQueue)
final deleteQueueProvider = DeleteQueueProvider._();

final class DeleteQueueProvider
    extends $FunctionalProvider<DeleteQueue, DeleteQueue, DeleteQueue>
    with $Provider<DeleteQueue> {
  DeleteQueueProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deleteQueueProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deleteQueueHash();

  @$internal
  @override
  $ProviderElement<DeleteQueue> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DeleteQueue create(Ref ref) {
    return deleteQueue(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DeleteQueue value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DeleteQueue>(value),
    );
  }
}

String _$deleteQueueHash() => r'cb52c54295f8123ee99afc007b2ed5baffbc9001';

@ProviderFor(undoService)
final undoServiceProvider = UndoServiceProvider._();

final class UndoServiceProvider
    extends $FunctionalProvider<UndoService, UndoService, UndoService>
    with $Provider<UndoService> {
  UndoServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'undoServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$undoServiceHash();

  @$internal
  @override
  $ProviderElement<UndoService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  UndoService create(Ref ref) {
    return undoService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UndoService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UndoService>(value),
    );
  }
}

String _$undoServiceHash() => r'6db80491165ad290b0fd3c3e7b49b644de7e8d25';

/// Commit problems that aren't per file (shown as a snackbar).

@ProviderFor(deleteQueueErrors)
final deleteQueueErrorsProvider = DeleteQueueErrorsProvider._();

/// Commit problems that aren't per file (shown as a snackbar).

final class DeleteQueueErrorsProvider
    extends $FunctionalProvider<AsyncValue<Object>, Object, Stream<Object>>
    with $FutureModifier<Object>, $StreamProvider<Object> {
  /// Commit problems that aren't per file (shown as a snackbar).
  DeleteQueueErrorsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deleteQueueErrorsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deleteQueueErrorsHash();

  @$internal
  @override
  $StreamProviderElement<Object> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<Object> create(Ref ref) {
    return deleteQueueErrors(ref);
  }
}

String _$deleteQueueErrorsHash() => r'8ee84d7a5c518584dff394bb78578f9e308b6cbf';

@ProviderFor(undoableCount)
final undoableCountProvider = UndoableCountFamily._();

final class UndoableCountProvider
    extends $FunctionalProvider<AsyncValue<int>, int, Stream<int>>
    with $FutureModifier<int>, $StreamProvider<int> {
  UndoableCountProvider._({
    required UndoableCountFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'undoableCountProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$undoableCountHash();

  @override
  String toString() {
    return r'undoableCountProvider'
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
    return undoableCount(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is UndoableCountProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$undoableCountHash() => r'f3ea0e9435d919b35b92f978426ba6d690079591';

final class UndoableCountFamily extends $Family
    with $FunctionalFamilyOverride<Stream<int>, int> {
  UndoableCountFamily._()
    : super(
        retry: null,
        name: r'undoableCountProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  UndoableCountProvider call(int sessionId) =>
      UndoableCountProvider._(argument: sessionId, from: this);

  @override
  String toString() => r'undoableCountProvider';
}

@ProviderFor(pendingDeleteSummary)
final pendingDeleteSummaryProvider = PendingDeleteSummaryFamily._();

final class PendingDeleteSummaryProvider
    extends
        $FunctionalProvider<
          AsyncValue<PendingDeleteSummary>,
          PendingDeleteSummary,
          Stream<PendingDeleteSummary>
        >
    with
        $FutureModifier<PendingDeleteSummary>,
        $StreamProvider<PendingDeleteSummary> {
  PendingDeleteSummaryProvider._({
    required PendingDeleteSummaryFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'pendingDeleteSummaryProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$pendingDeleteSummaryHash();

  @override
  String toString() {
    return r'pendingDeleteSummaryProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<PendingDeleteSummary> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<PendingDeleteSummary> create(Ref ref) {
    final argument = this.argument as int;
    return pendingDeleteSummary(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PendingDeleteSummaryProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$pendingDeleteSummaryHash() =>
    r'f9195dbf817af51afca58474672f90ae8452dbdc';

final class PendingDeleteSummaryFamily extends $Family
    with $FunctionalFamilyOverride<Stream<PendingDeleteSummary>, int> {
  PendingDeleteSummaryFamily._()
    : super(
        retry: null,
        name: r'pendingDeleteSummaryProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  PendingDeleteSummaryProvider call(int sessionId) =>
      PendingDeleteSummaryProvider._(argument: sessionId, from: this);

  @override
  String toString() => r'pendingDeleteSummaryProvider';
}
