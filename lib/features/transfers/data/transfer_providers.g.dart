// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transfer_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(transfersRepository)
final transfersRepositoryProvider = TransfersRepositoryProvider._();

final class TransfersRepositoryProvider
    extends
        $FunctionalProvider<
          TransfersRepository,
          TransfersRepository,
          TransfersRepository
        >
    with $Provider<TransfersRepository> {
  TransfersRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'transfersRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$transfersRepositoryHash();

  @$internal
  @override
  $ProviderElement<TransfersRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TransfersRepository create(Ref ref) {
    return transfersRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TransfersRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TransfersRepository>(value),
    );
  }
}

String _$transfersRepositoryHash() =>
    r'eac764dcefb05f81824c4e1081c15abdcaf6aefd';

/// Runs before an upload reads a file: X2 strips location from photos and
/// videos while "Remove location when sharing" is on (read per file, so a
/// change applies to the next file), else the file is sent as it is.

@ProviderFor(transferPreprocessor)
final transferPreprocessorProvider = TransferPreprocessorProvider._();

/// Runs before an upload reads a file: X2 strips location from photos and
/// videos while "Remove location when sharing" is on (read per file, so a
/// change applies to the next file), else the file is sent as it is.

final class TransferPreprocessorProvider
    extends
        $FunctionalProvider<
          TransferPreprocessor,
          TransferPreprocessor,
          TransferPreprocessor
        >
    with $Provider<TransferPreprocessor> {
  /// Runs before an upload reads a file: X2 strips location from photos and
  /// videos while "Remove location when sharing" is on (read per file, so a
  /// change applies to the next file), else the file is sent as it is.
  TransferPreprocessorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'transferPreprocessorProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$transferPreprocessorHash();

  @$internal
  @override
  $ProviderElement<TransferPreprocessor> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TransferPreprocessor create(Ref ref) {
    return transferPreprocessor(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TransferPreprocessor value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TransferPreprocessor>(value),
    );
  }
}

String _$transferPreprocessorHash() =>
    r'52b29933aca008f8fd38e355f85e9345d12d0585';

/// Where partials are written (tests override it with a temp folder).

@ProviderFor(transferStaging)
final transferStagingProvider = TransferStagingProvider._();

/// Where partials are written (tests override it with a temp folder).

final class TransferStagingProvider
    extends
        $FunctionalProvider<
          Future<Directory> Function(),
          Future<Directory> Function(),
          Future<Directory> Function()
        >
    with $Provider<Future<Directory> Function()> {
  /// Where partials are written (tests override it with a temp folder).
  TransferStagingProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'transferStagingProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$transferStagingHash();

  @$internal
  @override
  $ProviderElement<Future<Directory> Function()> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Future<Directory> Function() create(Ref ref) {
    return transferStaging(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Future<Directory> Function() value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Future<Directory> Function()>(value),
    );
  }
}

String _$transferStagingHash() => r'341c67255374c35a076ab573c544372843ee2ead';

/// The folder downloads go under by default: Android
/// `/storage/emulated/0/Download`, elsewhere `~/Downloads` (PL1).

@ProviderFor(downloadsRoot)
final downloadsRootProvider = DownloadsRootProvider._();

/// The folder downloads go under by default: Android
/// `/storage/emulated/0/Download`, elsewhere `~/Downloads` (PL1).

final class DownloadsRootProvider
    extends $FunctionalProvider<String, String, String>
    with $Provider<String> {
  /// The folder downloads go under by default: Android
  /// `/storage/emulated/0/Download`, elsewhere `~/Downloads` (PL1).
  DownloadsRootProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'downloadsRootProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$downloadsRootHash();

  @$internal
  @override
  $ProviderElement<String> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String create(Ref ref) {
    return downloadsRoot(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$downloadsRootHash() => r'293e3e8949ac1942965decfeafa047f6fa842907';

/// Deletes the originals of verified moves on this device (TASK-N11; U2
/// and X3 reuse it): under the history lock, deleted files leave the
/// index afterwards.

@ProviderFor(verifiedMove)
final verifiedMoveProvider = VerifiedMoveProvider._();

/// Deletes the originals of verified moves on this device (TASK-N11; U2
/// and X3 reuse it): under the history lock, deleted files leave the
/// index afterwards.

final class VerifiedMoveProvider
    extends $FunctionalProvider<VerifiedMove, VerifiedMove, VerifiedMove>
    with $Provider<VerifiedMove> {
  /// Deletes the originals of verified moves on this device (TASK-N11; U2
  /// and X3 reuse it): under the history lock, deleted files leave the
  /// index afterwards.
  VerifiedMoveProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'verifiedMoveProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$verifiedMoveHash();

  @$internal
  @override
  $ProviderElement<VerifiedMove> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  VerifiedMove create(Ref ref) {
    return verifiedMove(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VerifiedMove value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VerifiedMove>(value),
    );
  }
}

String _$verifiedMoveHash() => r'79abe7e1c0d4a23a5069e71efc0a898a6369f9fd';

/// The Wi-Fi transfer engine (TASK-N9). The app watches it once, so it
/// lives (and follows the connection) as long as the app.

@ProviderFor(transferEngine)
final transferEngineProvider = TransferEngineProvider._();

/// The Wi-Fi transfer engine (TASK-N9). The app watches it once, so it
/// lives (and follows the connection) as long as the app.

final class TransferEngineProvider
    extends $FunctionalProvider<TransferEngine, TransferEngine, TransferEngine>
    with $Provider<TransferEngine> {
  /// The Wi-Fi transfer engine (TASK-N9). The app watches it once, so it
  /// lives (and follows the connection) as long as the app.
  TransferEngineProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'transferEngineProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$transferEngineHash();

  @$internal
  @override
  $ProviderElement<TransferEngine> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TransferEngine create(Ref ref) {
    return transferEngine(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TransferEngine value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TransferEngine>(value),
    );
  }
}

String _$transferEngineHash() => r'99a67643233c85793e3524189ffee21f176dfd7d';

/// Every job, newest first (Transfers page).

@ProviderFor(transferJobs)
final transferJobsProvider = TransferJobsProvider._();

/// Every job, newest first (Transfers page).

final class TransferJobsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<TransferJob>>,
          List<TransferJob>,
          Stream<List<TransferJob>>
        >
    with
        $FutureModifier<List<TransferJob>>,
        $StreamProvider<List<TransferJob>> {
  /// Every job, newest first (Transfers page).
  TransferJobsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'transferJobsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$transferJobsHash();

  @$internal
  @override
  $StreamProviderElement<List<TransferJob>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<TransferJob>> create(Ref ref) {
    return transferJobs(ref);
  }
}

String _$transferJobsHash() => r'1c51614e21633baa24ac52941e9c11f5f7245cd0';

/// Live bytes and speeds of running files.

@ProviderFor(transferLive)
final transferLiveProvider = TransferLiveProvider._();

/// Live bytes and speeds of running files.

final class TransferLiveProvider
    extends
        $FunctionalProvider<
          AsyncValue<TransferLive>,
          TransferLive,
          Stream<TransferLive>
        >
    with $FutureModifier<TransferLive>, $StreamProvider<TransferLive> {
  /// Live bytes and speeds of running files.
  TransferLiveProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'transferLiveProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$transferLiveHash();

  @$internal
  @override
  $StreamProviderElement<TransferLive> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<TransferLive> create(Ref ref) {
    return transferLive(ref);
  }
}

String _$transferLiveHash() => r'35f62984fdbf206e0a3de02115f1a639bdb92b6a';

/// Jobs queued or running (settings row, badge).

@ProviderFor(activeTransferCount)
final activeTransferCountProvider = ActiveTransferCountProvider._();

/// Jobs queued or running (settings row, badge).

final class ActiveTransferCountProvider
    extends $FunctionalProvider<int, int, int>
    with $Provider<int> {
  /// Jobs queued or running (settings row, badge).
  ActiveTransferCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeTransferCountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeTransferCountHash();

  @$internal
  @override
  $ProviderElement<int> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  int create(Ref ref) {
    return activeTransferCount(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$activeTransferCountHash() =>
    r'36205e0a21dde3fe889184c2fbbd255358cee0ef';

/// Jobs running right now (the swipe screen's badge shows only then).

@ProviderFor(runningTransferCount)
final runningTransferCountProvider = RunningTransferCountProvider._();

/// Jobs running right now (the swipe screen's badge shows only then).

final class RunningTransferCountProvider
    extends $FunctionalProvider<int, int, int>
    with $Provider<int> {
  /// Jobs running right now (the swipe screen's badge shows only then).
  RunningTransferCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'runningTransferCountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$runningTransferCountHash();

  @$internal
  @override
  $ProviderElement<int> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  int create(Ref ref) {
    return runningTransferCount(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$runningTransferCountHash() =>
    r'f62c634952516e4541460a3d78a888626f9ca811';
