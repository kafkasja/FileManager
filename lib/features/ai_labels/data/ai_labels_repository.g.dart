// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_labels_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(aiLabelsRepository)
final aiLabelsRepositoryProvider = AiLabelsRepositoryProvider._();

final class AiLabelsRepositoryProvider
    extends
        $FunctionalProvider<
          AiLabelsRepository,
          AiLabelsRepository,
          AiLabelsRepository
        >
    with $Provider<AiLabelsRepository> {
  AiLabelsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'aiLabelsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$aiLabelsRepositoryHash();

  @$internal
  @override
  $ProviderElement<AiLabelsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AiLabelsRepository create(Ref ref) {
    return aiLabelsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AiLabelsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AiLabelsRepository>(value),
    );
  }
}

String _$aiLabelsRepositoryHash() =>
    r'7dfa8eca9395229ea0ae2b78d30bfd0e88327589';
