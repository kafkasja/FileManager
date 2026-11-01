// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'smart_groups_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(smartGroupsRepository)
final smartGroupsRepositoryProvider = SmartGroupsRepositoryProvider._();

final class SmartGroupsRepositoryProvider
    extends
        $FunctionalProvider<
          SmartGroupsRepository,
          SmartGroupsRepository,
          SmartGroupsRepository
        >
    with $Provider<SmartGroupsRepository> {
  SmartGroupsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'smartGroupsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$smartGroupsRepositoryHash();

  @$internal
  @override
  $ProviderElement<SmartGroupsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SmartGroupsRepository create(Ref ref) {
    return smartGroupsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SmartGroupsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SmartGroupsRepository>(value),
    );
  }
}

String _$smartGroupsRepositoryHash() =>
    r'2d7864e33a74b33db15f1695c396bcb0649e6971';
