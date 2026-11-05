// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'link_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// TASK-E1 two-way link: both devices run a server and each is the
/// other's client. Owns the server's lifetime while a link is active (not
/// a widget's dispose), the back-link (`/v1/link` → `/v1/link/join`), each
/// side's own perms (scope + take prompt) and the link's end on either
/// side. `RemoteConnectionController` stays single-peer.

@ProviderFor(LinkController)
final linkControllerProvider = LinkControllerProvider._();

/// TASK-E1 two-way link: both devices run a server and each is the
/// other's client. Owns the server's lifetime while a link is active (not
/// a widget's dispose), the back-link (`/v1/link` → `/v1/link/join`), each
/// side's own perms (scope + take prompt) and the link's end on either
/// side. `RemoteConnectionController` stays single-peer.
final class LinkControllerProvider
    extends $NotifierProvider<LinkController, LinkInfo?> {
  /// TASK-E1 two-way link: both devices run a server and each is the
  /// other's client. Owns the server's lifetime while a link is active (not
  /// a widget's dispose), the back-link (`/v1/link` → `/v1/link/join`), each
  /// side's own perms (scope + take prompt) and the link's end on either
  /// side. `RemoteConnectionController` stays single-peer.
  LinkControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'linkControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$linkControllerHash();

  @$internal
  @override
  LinkController create() => LinkController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LinkInfo? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LinkInfo?>(value),
    );
  }
}

String _$linkControllerHash() => r'6c5ce9eee8c89ab8d8bf9fb3fc025f6f3ecc9534';

/// TASK-E1 two-way link: both devices run a server and each is the
/// other's client. Owns the server's lifetime while a link is active (not
/// a widget's dispose), the back-link (`/v1/link` → `/v1/link/join`), each
/// side's own perms (scope + take prompt) and the link's end on either
/// side. `RemoteConnectionController` stays single-peer.

abstract class _$LinkController extends $Notifier<LinkInfo?> {
  LinkInfo? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<LinkInfo?, LinkInfo?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<LinkInfo?, LinkInfo?>,
              LinkInfo?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
