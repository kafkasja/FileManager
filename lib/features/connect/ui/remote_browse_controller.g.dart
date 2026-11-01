// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'remote_browse_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Pages one folder of a connected device (TASK-N7): roots → folders →
/// files, keyset paging through [RemoteFileSource.page], sort and type
/// filter. Live sync: when the heartbeat's change token changes, it
/// re-pages from the start up to the loaded count (at most
/// [maxRefreshItems]) after [refreshDelay] and replaces the items only when
/// something differs, so the grid keeps its scroll position; a failed
/// refresh keeps the old items. Errors (also "not connected") are
/// `AsyncError` (rule 8).

@ProviderFor(RemoteBrowseController)
final remoteBrowseControllerProvider = RemoteBrowseControllerFamily._();

/// Pages one folder of a connected device (TASK-N7): roots → folders →
/// files, keyset paging through [RemoteFileSource.page], sort and type
/// filter. Live sync: when the heartbeat's change token changes, it
/// re-pages from the start up to the loaded count (at most
/// [maxRefreshItems]) after [refreshDelay] and replaces the items only when
/// something differs, so the grid keeps its scroll position; a failed
/// refresh keeps the old items. Errors (also "not connected") are
/// `AsyncError` (rule 8).
final class RemoteBrowseControllerProvider
    extends $AsyncNotifierProvider<RemoteBrowseController, RemoteBrowseState> {
  /// Pages one folder of a connected device (TASK-N7): roots → folders →
  /// files, keyset paging through [RemoteFileSource.page], sort and type
  /// filter. Live sync: when the heartbeat's change token changes, it
  /// re-pages from the start up to the loaded count (at most
  /// [maxRefreshItems]) after [refreshDelay] and replaces the items only when
  /// something differs, so the grid keeps its scroll position; a failed
  /// refresh keeps the old items. Errors (also "not connected") are
  /// `AsyncError` (rule 8).
  RemoteBrowseControllerProvider._({
    required RemoteBrowseControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: _noRetry,
         name: r'remoteBrowseControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$remoteBrowseControllerHash();

  @override
  String toString() {
    return r'remoteBrowseControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  RemoteBrowseController create() => RemoteBrowseController();

  @override
  bool operator ==(Object other) {
    return other is RemoteBrowseControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$remoteBrowseControllerHash() =>
    r'8e5940aa02c489978fe91838319afb9bac99b570';

/// Pages one folder of a connected device (TASK-N7): roots → folders →
/// files, keyset paging through [RemoteFileSource.page], sort and type
/// filter. Live sync: when the heartbeat's change token changes, it
/// re-pages from the start up to the loaded count (at most
/// [maxRefreshItems]) after [refreshDelay] and replaces the items only when
/// something differs, so the grid keeps its scroll position; a failed
/// refresh keeps the old items. Errors (also "not connected") are
/// `AsyncError` (rule 8).

final class RemoteBrowseControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          RemoteBrowseController,
          AsyncValue<RemoteBrowseState>,
          RemoteBrowseState,
          FutureOr<RemoteBrowseState>,
          String
        > {
  RemoteBrowseControllerFamily._()
    : super(
        retry: _noRetry,
        name: r'remoteBrowseControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Pages one folder of a connected device (TASK-N7): roots → folders →
  /// files, keyset paging through [RemoteFileSource.page], sort and type
  /// filter. Live sync: when the heartbeat's change token changes, it
  /// re-pages from the start up to the loaded count (at most
  /// [maxRefreshItems]) after [refreshDelay] and replaces the items only when
  /// something differs, so the grid keeps its scroll position; a failed
  /// refresh keeps the old items. Errors (also "not connected") are
  /// `AsyncError` (rule 8).

  RemoteBrowseControllerProvider call(String peerFingerprint) =>
      RemoteBrowseControllerProvider._(argument: peerFingerprint, from: this);

  @override
  String toString() => r'remoteBrowseControllerProvider';
}

/// Pages one folder of a connected device (TASK-N7): roots → folders →
/// files, keyset paging through [RemoteFileSource.page], sort and type
/// filter. Live sync: when the heartbeat's change token changes, it
/// re-pages from the start up to the loaded count (at most
/// [maxRefreshItems]) after [refreshDelay] and replaces the items only when
/// something differs, so the grid keeps its scroll position; a failed
/// refresh keeps the old items. Errors (also "not connected") are
/// `AsyncError` (rule 8).

abstract class _$RemoteBrowseController
    extends $AsyncNotifier<RemoteBrowseState> {
  late final _$args = ref.$arg as String;
  String get peerFingerprint => _$args;

  FutureOr<RemoteBrowseState> build(String peerFingerprint);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<RemoteBrowseState>, RemoteBrowseState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<RemoteBrowseState>, RemoteBrowseState>,
              AsyncValue<RemoteBrowseState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
