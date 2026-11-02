// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'remote_swipe_screen.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// N8: the active swipe sessions on other devices, newest first.

@ProviderFor(remoteSwipeSessions)
final remoteSwipeSessionsProvider = RemoteSwipeSessionsProvider._();

/// N8: the active swipe sessions on other devices, newest first.

final class RemoteSwipeSessionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Session>>,
          List<Session>,
          Stream<List<Session>>
        >
    with $FutureModifier<List<Session>>, $StreamProvider<List<Session>> {
  /// N8: the active swipe sessions on other devices, newest first.
  RemoteSwipeSessionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'remoteSwipeSessionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$remoteSwipeSessionsHash();

  @$internal
  @override
  $StreamProviderElement<List<Session>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Session>> create(Ref ref) {
    return remoteSwipeSessions(ref);
  }
}

String _$remoteSwipeSessionsHash() =>
    r'70cbbd231061e36951053ce04704ecca1e09acc9';
