// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'swipe_source_launcher.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Opens a swipe source on the active session (TASK-SS1). Callers then go to
/// the swipe tab themselves:
///
///   final r = await ref.read(swipeSourceLauncherProvider.notifier).open(req);
///   if (!context.mounted) return;
///   if (r is SwipeSourceOpened) context.go(AppRoutes.swipe);
///   showSwipeSourceResult(context, r);

@ProviderFor(SwipeSourceLauncher)
final swipeSourceLauncherProvider = SwipeSourceLauncherProvider._();

/// Opens a swipe source on the active session (TASK-SS1). Callers then go to
/// the swipe tab themselves:
///
///   final r = await ref.read(swipeSourceLauncherProvider.notifier).open(req);
///   if (!context.mounted) return;
///   if (r is SwipeSourceOpened) context.go(AppRoutes.swipe);
///   showSwipeSourceResult(context, r);
final class SwipeSourceLauncherProvider
    extends $NotifierProvider<SwipeSourceLauncher, PreparedSource?> {
  /// Opens a swipe source on the active session (TASK-SS1). Callers then go to
  /// the swipe tab themselves:
  ///
  ///   final r = await ref.read(swipeSourceLauncherProvider.notifier).open(req);
  ///   if (!context.mounted) return;
  ///   if (r is SwipeSourceOpened) context.go(AppRoutes.swipe);
  ///   showSwipeSourceResult(context, r);
  SwipeSourceLauncherProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'swipeSourceLauncherProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$swipeSourceLauncherHash();

  @$internal
  @override
  SwipeSourceLauncher create() => SwipeSourceLauncher();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PreparedSource? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PreparedSource?>(value),
    );
  }
}

String _$swipeSourceLauncherHash() =>
    r'6036d7d9d44370d1e83f35d13c6fde94e04825c7';

/// Opens a swipe source on the active session (TASK-SS1). Callers then go to
/// the swipe tab themselves:
///
///   final r = await ref.read(swipeSourceLauncherProvider.notifier).open(req);
///   if (!context.mounted) return;
///   if (r is SwipeSourceOpened) context.go(AppRoutes.swipe);
///   showSwipeSourceResult(context, r);

abstract class _$SwipeSourceLauncher extends $Notifier<PreparedSource?> {
  PreparedSource? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<PreparedSource?, PreparedSource?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PreparedSource?, PreparedSource?>,
              PreparedSource?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
