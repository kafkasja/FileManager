// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'same_time_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// B3: the stored "taken within N seconds" window, clamped to 1–600.

@ProviderFor(sameTimeWindow)
final sameTimeWindowProvider = SameTimeWindowProvider._();

/// B3: the stored "taken within N seconds" window, clamped to 1–600.

final class SameTimeWindowProvider
    extends $FunctionalProvider<AsyncValue<int>, int, Stream<int>>
    with $FutureModifier<int>, $StreamProvider<int> {
  /// B3: the stored "taken within N seconds" window, clamped to 1–600.
  SameTimeWindowProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sameTimeWindowProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sameTimeWindowHash();

  @$internal
  @override
  $StreamProviderElement<int> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<int> create(Ref ref) {
    return sameTimeWindow(ref);
  }
}

String _$sameTimeWindowHash() => r'624a6ecc6895ad1b4d425a7e1c2d290943f2a1ef';

/// Groups of 2+ photos/videos of [query] taken within [windowSeconds] of
/// each other (TASK-B3). Only images and videos count; a query without
/// either (e.g. Documents) gives no groups and reads nothing. Recomputes
/// once after a scan, never during one.

@ProviderFor(SameTimeClusters)
final sameTimeClustersProvider = SameTimeClustersFamily._();

/// Groups of 2+ photos/videos of [query] taken within [windowSeconds] of
/// each other (TASK-B3). Only images and videos count; a query without
/// either (e.g. Documents) gives no groups and reads nothing. Recomputes
/// once after a scan, never during one.
final class SameTimeClustersProvider
    extends $AsyncNotifierProvider<SameTimeClusters, List<TimeCluster>> {
  /// Groups of 2+ photos/videos of [query] taken within [windowSeconds] of
  /// each other (TASK-B3). Only images and videos count; a query without
  /// either (e.g. Documents) gives no groups and reads nothing. Recomputes
  /// once after a scan, never during one.
  SameTimeClustersProvider._({
    required SameTimeClustersFamily super.from,
    required (IndexQuery, int) super.argument,
  }) : super(
         retry: null,
         name: r'sameTimeClustersProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$sameTimeClustersHash();

  @override
  String toString() {
    return r'sameTimeClustersProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  SameTimeClusters create() => SameTimeClusters();

  @override
  bool operator ==(Object other) {
    return other is SameTimeClustersProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$sameTimeClustersHash() => r'3664d454a44ffa5728d33a8857eb727935de7a71';

/// Groups of 2+ photos/videos of [query] taken within [windowSeconds] of
/// each other (TASK-B3). Only images and videos count; a query without
/// either (e.g. Documents) gives no groups and reads nothing. Recomputes
/// once after a scan, never during one.

final class SameTimeClustersFamily extends $Family
    with
        $ClassFamilyOverride<
          SameTimeClusters,
          AsyncValue<List<TimeCluster>>,
          List<TimeCluster>,
          FutureOr<List<TimeCluster>>,
          (IndexQuery, int)
        > {
  SameTimeClustersFamily._()
    : super(
        retry: null,
        name: r'sameTimeClustersProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Groups of 2+ photos/videos of [query] taken within [windowSeconds] of
  /// each other (TASK-B3). Only images and videos count; a query without
  /// either (e.g. Documents) gives no groups and reads nothing. Recomputes
  /// once after a scan, never during one.

  SameTimeClustersProvider call(IndexQuery query, int windowSeconds) =>
      SameTimeClustersProvider._(argument: (query, windowSeconds), from: this);

  @override
  String toString() => r'sameTimeClustersProvider';
}

/// Groups of 2+ photos/videos of [query] taken within [windowSeconds] of
/// each other (TASK-B3). Only images and videos count; a query without
/// either (e.g. Documents) gives no groups and reads nothing. Recomputes
/// once after a scan, never during one.

abstract class _$SameTimeClusters extends $AsyncNotifier<List<TimeCluster>> {
  late final _$args = ref.$arg as (IndexQuery, int);
  IndexQuery get query => _$args.$1;
  int get windowSeconds => _$args.$2;

  FutureOr<List<TimeCluster>> build(IndexQuery query, int windowSeconds);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<TimeCluster>>, List<TimeCluster>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<TimeCluster>>, List<TimeCluster>>,
              AsyncValue<List<TimeCluster>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args.$1, _$args.$2));
  }
}
