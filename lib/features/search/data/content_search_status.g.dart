// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'content_search_status.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(contentSearchStatus)
final contentSearchStatusProvider = ContentSearchStatusProvider._();

final class ContentSearchStatusProvider
    extends
        $FunctionalProvider<
          ContentSearchStatus,
          ContentSearchStatus,
          ContentSearchStatus
        >
    with $Provider<ContentSearchStatus> {
  ContentSearchStatusProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'contentSearchStatusProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$contentSearchStatusHash();

  @$internal
  @override
  $ProviderElement<ContentSearchStatus> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ContentSearchStatus create(Ref ref) {
    return contentSearchStatus(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ContentSearchStatus value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ContentSearchStatus>(value),
    );
  }
}

String _$contentSearchStatusHash() =>
    r'a469aeb5c3527935e86fe06f52dc31c63b74a3aa';
