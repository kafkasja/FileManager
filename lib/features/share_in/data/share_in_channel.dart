import 'package:flutter/services.dart';
import 'package:meta/meta.dart';

/// An event of `com.kaf.kfm/share_in/events` (TASK-X1, `ShareInChannel.kt`).
@immutable
sealed class ShareInEvent {
  const new(this.batchId);

  final String batchId;

  static ShareInEvent? fromMap(Map<Object?, Object?> m) {
    final id = m['batchId'];
    if (id is! String) return null;
    int number(Object? v) => v is int ? v : 0;
    return switch (m['type']) {
      'started' => ShareInStarted(id, count: number(m['count'])),
      'progress' => ShareInCopyProgress(
        id,
        index: number(m['index']),
        bytes: number(m['bytes']),
        total: number(m['total']),
      ),
      'ready' => ShareInReady(id),
      _ => null,
    };
  }
}

final class ShareInStarted extends ShareInEvent {
  const new(super.batchId, {required this.count});

  final int count;
}

final class ShareInCopyProgress extends ShareInEvent {
  const new(
    super.batchId, {
    required this.index,
    required this.bytes,
    required this.total,
  });

  final int index;
  final int bytes;
  final int total;
}

final class ShareInReady extends ShareInEvent {
  const new(super.batchId);
}

/// What Android hands over (see `ShareInChannel.kt`).
abstract interface class ShareInPlatform {
  /// The finished batch Android holds (then cleared), or null:
  /// `{id, receivedAtMs, items: [{kind: media|copy|failed, …}], notFiles}`.
  Future<Map<Object?, Object?>?> takePending();

  /// Copies [uri] into the batch's `shared_in` folder (a `media` item KFM
  /// can't see): a `copy` or `failed` item.
  Future<Map<Object?, Object?>> copyItem({
    required String batchId,
    required int receivedAtMs,
    required String uri,
  });

  /// Stops copying [batchId]'s items (partial files are removed).
  Future<void> cancel(String batchId);

  /// `<filesDir>/shared_in`.
  Future<String> root();

  Stream<ShareInEvent> events();
}

class ShareInChannel implements ShareInPlatform {
  new({MethodChannel? channel, EventChannel? events})
    : _channel = channel ?? const MethodChannel(name),
      _events = events ?? const EventChannel(eventsName);

  static const name = 'com.kaf.kfm/share_in';
  static const eventsName = 'com.kaf.kfm/share_in/events';

  final MethodChannel _channel;
  final EventChannel _events;

  late final Stream<ShareInEvent> _shared = _events
      .receiveBroadcastStream()
      .map((e) => e is Map ? ShareInEvent.fromMap(e) : null)
      .where((e) => e != null)
      .cast<ShareInEvent>();

  @override
  Future<Map<Object?, Object?>?> takePending() =>
      _channel.invokeMethod<Map<Object?, Object?>>('takePending');

  @override
  Future<Map<Object?, Object?>> copyItem({
    required String batchId,
    required int receivedAtMs,
    required String uri,
  }) async =>
      await _channel.invokeMethod<Map<Object?, Object?>>('copyItem', {
        'batchId': batchId,
        'receivedAtMs': receivedAtMs,
        'uri': uri,
      }) ??
      const {'kind': 'failed', 'error': 'ioError'};

  @override
  Future<void> cancel(String batchId) =>
      _channel.invokeMethod<void>('cancel', {'batchId': batchId});

  @override
  Future<String> root() async =>
      await _channel.invokeMethod<String>('root') ??
      (throw PlatformException(code: 'noRoot'));

  @override
  Stream<ShareInEvent> events() => _shared;
}
