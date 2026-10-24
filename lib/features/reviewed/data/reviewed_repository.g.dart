// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reviewed_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(reviewedRepository)
final reviewedRepositoryProvider = ReviewedRepositoryProvider._();

final class ReviewedRepositoryProvider
    extends
        $FunctionalProvider<
          ReviewedRepository,
          ReviewedRepository,
          ReviewedRepository
        >
    with $Provider<ReviewedRepository> {
  ReviewedRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reviewedRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reviewedRepositoryHash();

  @$internal
  @override
  $ProviderElement<ReviewedRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ReviewedRepository create(Ref ref) {
    return reviewedRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReviewedRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReviewedRepository>(value),
    );
  }
}

String _$reviewedRepositoryHash() =>
    r'01a365b24dc56e027f3337f68a9984f93e5fa642';

/// Newest label per preset for [file] (viewer info bar).

@ProviderFor(reviewedLabelsFor)
final reviewedLabelsForProvider = ReviewedLabelsForFamily._();

/// Newest label per preset for [file] (viewer info bar).

final class ReviewedLabelsForProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ReviewedLabel>>,
          List<ReviewedLabel>,
          FutureOr<List<ReviewedLabel>>
        >
    with
        $FutureModifier<List<ReviewedLabel>>,
        $FutureProvider<List<ReviewedLabel>> {
  /// Newest label per preset for [file] (viewer info bar).
  ReviewedLabelsForProvider._({
    required ReviewedLabelsForFamily super.from,
    required FileRef super.argument,
  }) : super(
         retry: null,
         name: r'reviewedLabelsForProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$reviewedLabelsForHash();

  @override
  String toString() {
    return r'reviewedLabelsForProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<ReviewedLabel>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ReviewedLabel>> create(Ref ref) {
    final argument = this.argument as FileRef;
    return reviewedLabelsFor(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ReviewedLabelsForProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$reviewedLabelsForHash() => r'9e375c3c9c9156a415dd9665e2e93b9efea84344';

/// Newest label per preset for [file] (viewer info bar).

final class ReviewedLabelsForFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<ReviewedLabel>>, FileRef> {
  ReviewedLabelsForFamily._()
    : super(
        retry: null,
        name: r'reviewedLabelsForProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Newest label per preset for [file] (viewer info bar).

  ReviewedLabelsForProvider call(FileRef file) =>
      ReviewedLabelsForProvider._(argument: file, from: this);

  @override
  String toString() => r'reviewedLabelsForProvider';
}
