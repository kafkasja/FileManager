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
    r'cc13c9ccc0d42e58082ddc268d1590fcd2db5df3';

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

/// Sound is per session, not per video. On by default: the phone's own
/// volume decides (user, 2026-11-04); the pill's speaker icon mutes until
/// it is tapped again.

@ProviderFor(VideoMuted)
final videoMutedProvider = VideoMutedProvider._();

/// Sound is per session, not per video. On by default: the phone's own
/// volume decides (user, 2026-11-04); the pill's speaker icon mutes until
/// it is tapped again.
final class VideoMutedProvider extends $NotifierProvider<VideoMuted, bool> {
  /// Sound is per session, not per video. On by default: the phone's own
  /// volume decides (user, 2026-11-04); the pill's speaker icon mutes until
  /// it is tapped again.
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

String _$videoMutedHash() => r'5adc82c89b774b0b8883c02f6de92ac06985ab1d';

/// Sound is per session, not per video. On by default: the phone's own
/// volume decides (user, 2026-11-04); the pill's speaker icon mutes until
/// it is tapped again.

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

/// Desktop: the videos the user paused (click on the video, the bar's
/// play/pause button, Space) and the phone (a tap on the video, user
/// 2026-11-04). A pause sticks until they play it again, whatever shows the
/// video next (deck, Quick look, the viewer).

@ProviderFor(VideoPaused)
final videoPausedProvider = VideoPausedProvider._();

/// Desktop: the videos the user paused (click on the video, the bar's
/// play/pause button, Space) and the phone (a tap on the video, user
/// 2026-11-04). A pause sticks until they play it again, whatever shows the
/// video next (deck, Quick look, the viewer).
final class VideoPausedProvider
    extends $NotifierProvider<VideoPaused, Set<String>> {
  /// Desktop: the videos the user paused (click on the video, the bar's
  /// play/pause button, Space) and the phone (a tap on the video, user
  /// 2026-11-04). A pause sticks until they play it again, whatever shows the
  /// video next (deck, Quick look, the viewer).
  VideoPausedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'videoPausedProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$videoPausedHash();

  @$internal
  @override
  VideoPaused create() => VideoPaused();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Set<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Set<String>>(value),
    );
  }
}

String _$videoPausedHash() => r'f0fe6e5f2f97d3e99116b0aed1daedd638eae040';

/// Desktop: the videos the user paused (click on the video, the bar's
/// play/pause button, Space) and the phone (a tap on the video, user
/// 2026-11-04). A pause sticks until they play it again, whatever shows the
/// video next (deck, Quick look, the viewer).

abstract class _$VideoPaused extends $Notifier<Set<String>> {
  Set<String> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<Set<String>, Set<String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Set<String>, Set<String>>,
              Set<String>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
