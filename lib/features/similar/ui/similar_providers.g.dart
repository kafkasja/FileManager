// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'similar_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether the finder is on (TASK-C2, off by default).

@ProviderFor(similarEnabled)
final similarEnabledProvider = SimilarEnabledProvider._();

/// Whether the finder is on (TASK-C2, off by default).

final class SimilarEnabledProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, Stream<bool>>
    with $FutureModifier<bool>, $StreamProvider<bool> {
  /// Whether the finder is on (TASK-C2, off by default).
  SimilarEnabledProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'similarEnabledProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$similarEnabledHash();

  @$internal
  @override
  $StreamProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<bool> create(Ref ref) {
    return similarEnabled(ref);
  }
}

String _$similarEnabledHash() => r'dfa5f4de42ac4940bcefe19731aa638d7f6b1bc7';

@ProviderFor(similarStrictness)
final similarStrictnessProvider = SimilarStrictnessProvider._();

final class SimilarStrictnessProvider
    extends $FunctionalProvider<AsyncValue<String>, String, Stream<String>>
    with $FutureModifier<String>, $StreamProvider<String> {
  SimilarStrictnessProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'similarStrictnessProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$similarStrictnessHash();

  @$internal
  @override
  $StreamProviderElement<String> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<String> create(Ref ref) {
    return similarStrictness(ref);
  }
}

String _$similarStrictnessHash() => r'f838c47a366b8f735eb6cce8381f66493dc14355';

@ProviderFor(similarIncludeScreenshots)
final similarIncludeScreenshotsProvider = SimilarIncludeScreenshotsProvider._();

final class SimilarIncludeScreenshotsProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, Stream<bool>>
    with $FutureModifier<bool>, $StreamProvider<bool> {
  SimilarIncludeScreenshotsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'similarIncludeScreenshotsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$similarIncludeScreenshotsHash();

  @$internal
  @override
  $StreamProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<bool> create(Ref ref) {
    return similarIncludeScreenshots(ref);
  }
}

String _$similarIncludeScreenshotsHash() =>
    r'6eb87351d4e35e4fcf59e46f09ce71d6376d527c';

@ProviderFor(similarGroups)
final similarGroupsProvider = SimilarGroupsProvider._();

final class SimilarGroupsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<SimilarGroup>>,
          List<SimilarGroup>,
          Stream<List<SimilarGroup>>
        >
    with
        $FutureModifier<List<SimilarGroup>>,
        $StreamProvider<List<SimilarGroup>> {
  SimilarGroupsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'similarGroupsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$similarGroupsHash();

  @$internal
  @override
  $StreamProviderElement<List<SimilarGroup>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<SimilarGroup>> create(Ref ref) {
    return similarGroups(ref);
  }
}

String _$similarGroupsHash() => r'17ff8a24be3f048602e776f02ed8e5c05c92e7cc';

@ProviderFor(similarBlurThreshold)
final similarBlurThresholdProvider = SimilarBlurThresholdProvider._();

final class SimilarBlurThresholdProvider
    extends $FunctionalProvider<AsyncValue<int>, int, Stream<int>>
    with $FutureModifier<int>, $StreamProvider<int> {
  SimilarBlurThresholdProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'similarBlurThresholdProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$similarBlurThresholdHash();

  @$internal
  @override
  $StreamProviderElement<int> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<int> create(Ref ref) {
    return similarBlurThreshold(ref);
  }
}

String _$similarBlurThresholdHash() =>
    r'a1cb2d30176a0dd5fc367d5c0155f2fdbb9fa35b';

@ProviderFor(similarBlurry)
final similarBlurryProvider = SimilarBlurryProvider._();

final class SimilarBlurryProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<FileRef>>,
          List<FileRef>,
          Stream<List<FileRef>>
        >
    with $FutureModifier<List<FileRef>>, $StreamProvider<List<FileRef>> {
  SimilarBlurryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'similarBlurryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$similarBlurryHash();

  @$internal
  @override
  $StreamProviderElement<List<FileRef>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<FileRef>> create(Ref ref) {
    return similarBlurry(ref);
  }
}

String _$similarBlurryHash() => r'3e376f0d17da0897561948bb9a17fe374aee4f00';
