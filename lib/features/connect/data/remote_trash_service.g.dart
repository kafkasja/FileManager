// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'remote_trash_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The banner the share screen shows while a client's request runs.

@ProviderFor(RemoteRequestNoticeState)
final remoteRequestNoticeStateProvider = RemoteRequestNoticeStateProvider._();

/// The banner the share screen shows while a client's request runs.
final class RemoteRequestNoticeStateProvider
    extends $NotifierProvider<RemoteRequestNoticeState, RemoteRequestNotice?> {
  /// The banner the share screen shows while a client's request runs.
  RemoteRequestNoticeStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'remoteRequestNoticeStateProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$remoteRequestNoticeStateHash();

  @$internal
  @override
  RemoteRequestNoticeState create() => RemoteRequestNoticeState();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RemoteRequestNotice? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RemoteRequestNotice?>(value),
    );
  }
}

String _$remoteRequestNoticeStateHash() =>
    r'b0cf3edffa58ea974451702fbd54644fd20a4589';

/// The banner the share screen shows while a client's request runs.

abstract class _$RemoteRequestNoticeState
    extends $Notifier<RemoteRequestNotice?> {
  RemoteRequestNotice? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<RemoteRequestNotice?, RemoteRequestNotice?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<RemoteRequestNotice?, RemoteRequestNotice?>,
              RemoteRequestNotice?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// The last finished client request (share screen snackbar).

@ProviderFor(RemoteRequestOutcomeState)
final remoteRequestOutcomeStateProvider = RemoteRequestOutcomeStateProvider._();

/// The last finished client request (share screen snackbar).
final class RemoteRequestOutcomeStateProvider
    extends
        $NotifierProvider<RemoteRequestOutcomeState, RemoteRequestOutcome?> {
  /// The last finished client request (share screen snackbar).
  RemoteRequestOutcomeStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'remoteRequestOutcomeStateProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$remoteRequestOutcomeStateHash();

  @$internal
  @override
  RemoteRequestOutcomeState create() => RemoteRequestOutcomeState();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RemoteRequestOutcome? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RemoteRequestOutcome?>(value),
    );
  }
}

String _$remoteRequestOutcomeStateHash() =>
    r'80eac826fb47c40646834173bf2cc4b05b84d3e4';

/// The last finished client request (share screen snackbar).

abstract class _$RemoteRequestOutcomeState
    extends $Notifier<RemoteRequestOutcome?> {
  RemoteRequestOutcome? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<RemoteRequestOutcome?, RemoteRequestOutcome?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<RemoteRequestOutcome?, RemoteRequestOutcome?>,
              RemoteRequestOutcome?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(remoteTrashService)
final remoteTrashServiceProvider = RemoteTrashServiceProvider._();

final class RemoteTrashServiceProvider
    extends
        $FunctionalProvider<
          RemoteTrashService,
          RemoteTrashService,
          RemoteTrashService
        >
    with $Provider<RemoteTrashService> {
  RemoteTrashServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'remoteTrashServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$remoteTrashServiceHash();

  @$internal
  @override
  $ProviderElement<RemoteTrashService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  RemoteTrashService create(Ref ref) {
    return remoteTrashService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RemoteTrashService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RemoteTrashService>(value),
    );
  }
}

String _$remoteTrashServiceHash() =>
    r'837bf5a20e8b050a811068e97113bf68b1dc9264';
