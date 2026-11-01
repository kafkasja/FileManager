// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'share_server_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Starts and stops "Share this device" (TASK-N1). The share screen calls
/// [startSharing] when opened and [stopSharing] on dispose; N5 adds the
/// app-lifecycle hook here. Errors land in [ShareServerState.error] (rule 8).

@ProviderFor(ShareServerController)
final shareServerControllerProvider = ShareServerControllerProvider._();

/// Starts and stops "Share this device" (TASK-N1). The share screen calls
/// [startSharing] when opened and [stopSharing] on dispose; N5 adds the
/// app-lifecycle hook here. Errors land in [ShareServerState.error] (rule 8).
final class ShareServerControllerProvider
    extends $NotifierProvider<ShareServerController, ShareServerState> {
  /// Starts and stops "Share this device" (TASK-N1). The share screen calls
  /// [startSharing] when opened and [stopSharing] on dispose; N5 adds the
  /// app-lifecycle hook here. Errors land in [ShareServerState.error] (rule 8).
  ShareServerControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'shareServerControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$shareServerControllerHash();

  @$internal
  @override
  ShareServerController create() => ShareServerController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ShareServerState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ShareServerState>(value),
    );
  }
}

String _$shareServerControllerHash() =>
    r'0ebe50ddeb801b904fc7f1797538dcf96a4d2259';

/// Starts and stops "Share this device" (TASK-N1). The share screen calls
/// [startSharing] when opened and [stopSharing] on dispose; N5 adds the
/// app-lifecycle hook here. Errors land in [ShareServerState.error] (rule 8).

abstract class _$ShareServerController extends $Notifier<ShareServerState> {
  ShareServerState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ShareServerState, ShareServerState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ShareServerState, ShareServerState>,
              ShareServerState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
