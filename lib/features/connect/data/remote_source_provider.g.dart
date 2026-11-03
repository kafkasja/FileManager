// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'remote_source_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether the device with [peerFingerprint] is connected now.

@ProviderFor(remotePeerConnected)
final remotePeerConnectedProvider = RemotePeerConnectedFamily._();

/// Whether the device with [peerFingerprint] is connected now.

final class RemotePeerConnectedProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Whether the device with [peerFingerprint] is connected now.
  RemotePeerConnectedProvider._({
    required RemotePeerConnectedFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'remotePeerConnectedProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$remotePeerConnectedHash();

  @override
  String toString() {
    return r'remotePeerConnectedProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    final argument = this.argument as String;
    return remotePeerConnected(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is RemotePeerConnectedProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$remotePeerConnectedHash() =>
    r'b1bcfd4a24fc355b5dbad5b120a0e97f600e4009';

/// Whether the device with [peerFingerprint] is connected now.

final class RemotePeerConnectedFamily extends $Family
    with $FunctionalFamilyOverride<bool, String> {
  RemotePeerConnectedFamily._()
    : super(
        retry: null,
        name: r'remotePeerConnectedProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Whether the device with [peerFingerprint] is connected now.

  RemotePeerConnectedProvider call(String peerFingerprint) =>
      RemotePeerConnectedProvider._(argument: peerFingerprint, from: this);

  @override
  String toString() => r'remotePeerConnectedProvider';
}

/// The files of the device with [peerFingerprint] (TASK-N7). Lives as long
/// as the app; it reads the live connection's client per call, so while that
/// device isn't connected every call throws `FileOpFailure.unavailable`.
/// Its id changes (remote move / rename) re-key B's tags, favorites and
/// reviewed labels like local ones (F3 → `FileIdRekeyer`).

@ProviderFor(remoteSource)
final remoteSourceProvider = RemoteSourceFamily._();

/// The files of the device with [peerFingerprint] (TASK-N7). Lives as long
/// as the app; it reads the live connection's client per call, so while that
/// device isn't connected every call throws `FileOpFailure.unavailable`.
/// Its id changes (remote move / rename) re-key B's tags, favorites and
/// reviewed labels like local ones (F3 → `FileIdRekeyer`).

final class RemoteSourceProvider
    extends
        $FunctionalProvider<
          RemoteFileSource,
          RemoteFileSource,
          RemoteFileSource
        >
    with $Provider<RemoteFileSource> {
  /// The files of the device with [peerFingerprint] (TASK-N7). Lives as long
  /// as the app; it reads the live connection's client per call, so while that
  /// device isn't connected every call throws `FileOpFailure.unavailable`.
  /// Its id changes (remote move / rename) re-key B's tags, favorites and
  /// reviewed labels like local ones (F3 → `FileIdRekeyer`).
  RemoteSourceProvider._({
    required RemoteSourceFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'remoteSourceProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$remoteSourceHash();

  @override
  String toString() {
    return r'remoteSourceProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<RemoteFileSource> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  RemoteFileSource create(Ref ref) {
    final argument = this.argument as String;
    return remoteSource(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RemoteFileSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RemoteFileSource>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is RemoteSourceProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$remoteSourceHash() => r'f4d70ae5a5afe046d9103fd9a6041195f9a3d949';

/// The files of the device with [peerFingerprint] (TASK-N7). Lives as long
/// as the app; it reads the live connection's client per call, so while that
/// device isn't connected every call throws `FileOpFailure.unavailable`.
/// Its id changes (remote move / rename) re-key B's tags, favorites and
/// reviewed labels like local ones (F3 → `FileIdRekeyer`).

final class RemoteSourceFamily extends $Family
    with $FunctionalFamilyOverride<RemoteFileSource, String> {
  RemoteSourceFamily._()
    : super(
        retry: null,
        name: r'remoteSourceProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// The files of the device with [peerFingerprint] (TASK-N7). Lives as long
  /// as the app; it reads the live connection's client per call, so while that
  /// device isn't connected every call throws `FileOpFailure.unavailable`.
  /// Its id changes (remote move / rename) re-key B's tags, favorites and
  /// reviewed labels like local ones (F3 → `FileIdRekeyer`).

  RemoteSourceProvider call(String peerFingerprint) =>
      RemoteSourceProvider._(argument: peerFingerprint, from: this);

  @override
  String toString() => r'remoteSourceProvider';
}
