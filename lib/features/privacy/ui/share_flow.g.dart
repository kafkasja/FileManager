// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'share_flow.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Android `ACTION_SEND(_MULTIPLE)` (tests override it).

@ProviderFor(shareSheet)
final shareSheetProvider = ShareSheetProvider._();

/// Android `ACTION_SEND(_MULTIPLE)` (tests override it).

final class ShareSheetProvider
    extends $FunctionalProvider<ShareSheet, ShareSheet, ShareSheet>
    with $Provider<ShareSheet> {
  /// Android `ACTION_SEND(_MULTIPLE)` (tests override it).
  ShareSheetProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'shareSheetProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$shareSheetHash();

  @$internal
  @override
  $ProviderElement<ShareSheet> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ShareSheet create(Ref ref) {
    return shareSheet(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ShareSheet value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ShareSheet>(value),
    );
  }
}

String _$shareSheetHash() => r'aea387d8df6408f62f50ec2ff2f70de5c3c8ca4d';
