// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'smart_groups_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(groupsComputer)
final groupsComputerProvider = GroupsComputerProvider._();

final class GroupsComputerProvider
    extends $FunctionalProvider<GroupsComputer, GroupsComputer, GroupsComputer>
    with $Provider<GroupsComputer> {
  GroupsComputerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'groupsComputerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$groupsComputerHash();

  @$internal
  @override
  $ProviderElement<GroupsComputer> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GroupsComputer create(Ref ref) {
    return groupsComputer(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GroupsComputer value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GroupsComputer>(value),
    );
  }
}

String _$groupsComputerHash() => r'69aacc9270104cd8ae8d2bc417becb81e8346034';

@ProviderFor(exifReader)
final exifReaderProvider = ExifReaderProvider._();

final class ExifReaderProvider
    extends $FunctionalProvider<ExifReader, ExifReader, ExifReader>
    with $Provider<ExifReader> {
  ExifReaderProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'exifReaderProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$exifReaderHash();

  @$internal
  @override
  $ProviderElement<ExifReader> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ExifReader create(Ref ref) {
    return exifReader(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ExifReader value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ExifReader>(value),
    );
  }
}

String _$exifReaderHash() => r'3d2e0b24c41cd101edef1b4f44844d882ae09e5e';

/// Registers the groups job with the in-app runner (watched in `App.build`)
/// and kicks it when Groups is activated or online names are turned on.

@ProviderFor(smartGroupsJob)
final smartGroupsJobProvider = SmartGroupsJobProvider._();

/// Registers the groups job with the in-app runner (watched in `App.build`)
/// and kicks it when Groups is activated or online names are turned on.

final class SmartGroupsJobProvider
    extends $FunctionalProvider<SmartGroupsJob, SmartGroupsJob, SmartGroupsJob>
    with $Provider<SmartGroupsJob> {
  /// Registers the groups job with the in-app runner (watched in `App.build`)
  /// and kicks it when Groups is activated or online names are turned on.
  SmartGroupsJobProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'smartGroupsJobProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$smartGroupsJobHash();

  @$internal
  @override
  $ProviderElement<SmartGroupsJob> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SmartGroupsJob create(Ref ref) {
    return smartGroupsJob(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SmartGroupsJob value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SmartGroupsJob>(value),
    );
  }
}

String _$smartGroupsJobHash() => r'1a0fbbf4b464b201035ee8defed33a81a854ec3e';

/// Job progress for the Groups screen ("Finding trips and places…").

@ProviderFor(smartGroupsProgress)
final smartGroupsProgressProvider = SmartGroupsProgressProvider._();

/// Job progress for the Groups screen ("Finding trips and places…").

final class SmartGroupsProgressProvider
    extends
        $FunctionalProvider<
          AsyncValue<SmartGroupsProgress>,
          SmartGroupsProgress,
          Stream<SmartGroupsProgress>
        >
    with
        $FutureModifier<SmartGroupsProgress>,
        $StreamProvider<SmartGroupsProgress> {
  /// Job progress for the Groups screen ("Finding trips and places…").
  SmartGroupsProgressProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'smartGroupsProgressProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$smartGroupsProgressHash();

  @$internal
  @override
  $StreamProviderElement<SmartGroupsProgress> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<SmartGroupsProgress> create(Ref ref) {
    return smartGroupsProgress(ref);
  }
}

String _$smartGroupsProgressHash() =>
    r'8b9a3a3dead35d81647af1dc6fee0dd0ae3ff562';

/// `ACCESS_MEDIA_LOCATION` (C5 §7). Checked when Groups opens; asked only
/// from [request] (first Groups open, the "Allow location access" row).

@ProviderFor(MediaLocationAccess)
final mediaLocationAccessProvider = MediaLocationAccessProvider._();

/// `ACCESS_MEDIA_LOCATION` (C5 §7). Checked when Groups opens; asked only
/// from [request] (first Groups open, the "Allow location access" row).
final class MediaLocationAccessProvider
    extends $AsyncNotifierProvider<MediaLocationAccess, bool> {
  /// `ACCESS_MEDIA_LOCATION` (C5 §7). Checked when Groups opens; asked only
  /// from [request] (first Groups open, the "Allow location access" row).
  MediaLocationAccessProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mediaLocationAccessProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mediaLocationAccessHash();

  @$internal
  @override
  MediaLocationAccess create() => MediaLocationAccess();
}

String _$mediaLocationAccessHash() =>
    r'81f9be6c7ae196d127bd69e64cba29b97a4937be';

/// `ACCESS_MEDIA_LOCATION` (C5 §7). Checked when Groups opens; asked only
/// from [request] (first Groups open, the "Allow location access" row).

abstract class _$MediaLocationAccess extends $AsyncNotifier<bool> {
  FutureOr<bool> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<bool>, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<bool>, bool>,
              AsyncValue<bool>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(smartGroupsOnlinePlaceNames)
final smartGroupsOnlinePlaceNamesProvider =
    SmartGroupsOnlinePlaceNamesProvider._();

final class SmartGroupsOnlinePlaceNamesProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, Stream<bool>>
    with $FutureModifier<bool>, $StreamProvider<bool> {
  SmartGroupsOnlinePlaceNamesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'smartGroupsOnlinePlaceNamesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$smartGroupsOnlinePlaceNamesHash();

  @$internal
  @override
  $StreamProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<bool> create(Ref ref) {
    return smartGroupsOnlinePlaceNames(ref);
  }
}

String _$smartGroupsOnlinePlaceNamesHash() =>
    r'7ddf030e81136dbce70fb04240d5a62a79261f00';

@ProviderFor(smartGroupList)
final smartGroupListProvider = SmartGroupListFamily._();

final class SmartGroupListProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<SmartGroupView>>,
          List<SmartGroupView>,
          Stream<List<SmartGroupView>>
        >
    with
        $FutureModifier<List<SmartGroupView>>,
        $StreamProvider<List<SmartGroupView>> {
  SmartGroupListProvider._({
    required SmartGroupListFamily super.from,
    required SmartGroupKind super.argument,
  }) : super(
         retry: null,
         name: r'smartGroupListProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$smartGroupListHash();

  @override
  String toString() {
    return r'smartGroupListProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<SmartGroupView>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<SmartGroupView>> create(Ref ref) {
    final argument = this.argument as SmartGroupKind;
    return smartGroupList(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is SmartGroupListProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$smartGroupListHash() => r'0f7b73909aeeb69778e7e512838c3cfd9d26620a';

final class SmartGroupListFamily extends $Family
    with
        $FunctionalFamilyOverride<
          Stream<List<SmartGroupView>>,
          SmartGroupKind
        > {
  SmartGroupListFamily._()
    : super(
        retry: null,
        name: r'smartGroupListProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SmartGroupListProvider call(SmartGroupKind kind) =>
      SmartGroupListProvider._(argument: kind, from: this);

  @override
  String toString() => r'smartGroupListProvider';
}

@ProviderFor(smartGroup)
final smartGroupProvider = SmartGroupFamily._();

final class SmartGroupProvider
    extends
        $FunctionalProvider<
          AsyncValue<SmartGroupView?>,
          SmartGroupView?,
          Stream<SmartGroupView?>
        >
    with $FutureModifier<SmartGroupView?>, $StreamProvider<SmartGroupView?> {
  SmartGroupProvider._({
    required SmartGroupFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'smartGroupProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$smartGroupHash();

  @override
  String toString() {
    return r'smartGroupProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<SmartGroupView?> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<SmartGroupView?> create(Ref ref) {
    final argument = this.argument as int;
    return smartGroup(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is SmartGroupProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$smartGroupHash() => r'fa700fe6c75743ccdc1e36ce220b9a58138b61f6';

final class SmartGroupFamily extends $Family
    with $FunctionalFamilyOverride<Stream<SmartGroupView?>, int> {
  SmartGroupFamily._()
    : super(
        retry: null,
        name: r'smartGroupProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SmartGroupProvider call(int id) =>
      SmartGroupProvider._(argument: id, from: this);

  @override
  String toString() => r'smartGroupProvider';
}

/// Count + newest file of a live group (hidden at 0). Respects `visible()`.

@ProviderFor(liveGroupSummary)
final liveGroupSummaryProvider = LiveGroupSummaryFamily._();

/// Count + newest file of a live group (hidden at 0). Respects `visible()`.

final class LiveGroupSummaryProvider
    extends
        $FunctionalProvider<
          AsyncValue<LiveGroupSummary>,
          LiveGroupSummary,
          FutureOr<LiveGroupSummary>
        >
    with $FutureModifier<LiveGroupSummary>, $FutureProvider<LiveGroupSummary> {
  /// Count + newest file of a live group (hidden at 0). Respects `visible()`.
  LiveGroupSummaryProvider._({
    required LiveGroupSummaryFamily super.from,
    required LiveGroup super.argument,
  }) : super(
         retry: null,
         name: r'liveGroupSummaryProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$liveGroupSummaryHash();

  @override
  String toString() {
    return r'liveGroupSummaryProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<LiveGroupSummary> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<LiveGroupSummary> create(Ref ref) {
    final argument = this.argument as LiveGroup;
    return liveGroupSummary(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is LiveGroupSummaryProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$liveGroupSummaryHash() => r'08118866cc4aa363cada026ecb74bfed076e7b2a';

/// Count + newest file of a live group (hidden at 0). Respects `visible()`.

final class LiveGroupSummaryFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<LiveGroupSummary>, LiveGroup> {
  LiveGroupSummaryFamily._()
    : super(
        retry: null,
        name: r'liveGroupSummaryProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Count + newest file of a live group (hidden at 0). Respects `visible()`.

  LiveGroupSummaryProvider call(LiveGroup group) =>
      LiveGroupSummaryProvider._(argument: group, from: this);

  @override
  String toString() => r'liveGroupSummaryProvider';
}
