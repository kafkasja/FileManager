// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_controller_pool.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(videoHandleFactory)
final videoHandleFactoryProvider = VideoHandleFactoryProvider._();

final class VideoHandleFactoryProvider
    extends
        $FunctionalProvider<
          VideoHandleFactory,
          VideoHandleFactory,
          VideoHandleFactory
        >
    with $Provider<VideoHandleFactory> {
  VideoHandleFactoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'videoHandleFactoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$videoHandleFactoryHash();

  @$internal
  @override
  $ProviderElement<VideoHandleFactory> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  VideoHandleFactory create(Ref ref) {
    return videoHandleFactory(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VideoHandleFactory value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VideoHandleFactory>(value),
    );
  }
}

String _$videoHandleFactoryHash() =>
    r'6f54346ae51b499b56dd23f59cfab4331db15dd5';

@ProviderFor(videoControllerPool)
final videoControllerPoolProvider = VideoControllerPoolProvider._();

final class VideoControllerPoolProvider
    extends
        $FunctionalProvider<
          VideoControllerPool,
          VideoControllerPool,
          VideoControllerPool
        >
    with $Provider<VideoControllerPool> {
  VideoControllerPoolProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'videoControllerPoolProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$videoControllerPoolHash();

  @$internal
  @override
  $ProviderElement<VideoControllerPool> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  VideoControllerPool create(Ref ref) {
    return videoControllerPool(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VideoControllerPool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VideoControllerPool>(value),
    );
  }
}

String _$videoControllerPoolHash() =>
    r'2809e5072d740d753fb093fa28f41e90c7e0c5d6';

/// Sound is per session, not per video: once on, following videos play
/// with sound until it's turned off (S5).

@ProviderFor(VideoMuted)
final videoMutedProvider = VideoMutedProvider._();

/// Sound is per session, not per video: once on, following videos play
/// with sound until it's turned off (S5).
final class VideoMutedProvider extends $NotifierProvider<VideoMuted, bool> {
  /// Sound is per session, not per video: once on, following videos play
  /// with sound until it's turned off (S5).
  VideoMutedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'videoMutedProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$videoMutedHash();

  @$internal
  @override
  VideoMuted create() => VideoMuted();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$videoMutedHash() => r'a69a723f95acd99ef5b9d9ade9e3c8012395267e';

/// Sound is per session, not per video: once on, following videos play
/// with sound until it's turned off (S5).

abstract class _$VideoMuted extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
