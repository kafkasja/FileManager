import 'dart:async';
import 'dart:io';

/// A streamed answer for `FakeRemoteHttp.streams` (N7 tests): [body] in
/// [chunkSize] chunks with [statusCode]. Members a test doesn't need throw.
class FakeHttpResponse extends Stream<List<int>> implements HttpClientResponse {
  new(this.body, {this.statusCode = 200, this.chunkSize = 4});

  final List<int> body;
  @override
  final int statusCode;
  final int chunkSize;

  /// Whether the reader cancelled before the end.
  bool cancelled = false;

  @override
  int get contentLength => body.length;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    final chunks = [
      for (var i = 0; i < body.length; i += chunkSize)
        body.sublist(i, (i + chunkSize).clamp(0, body.length)),
    ];
    final controller = StreamController<List<int>>(
      onCancel: () => cancelled = true,
    );
    unawaited(() async {
      for (final c in chunks) {
        if (controller.isClosed || cancelled) return;
        controller.add(c);
        // A microtask, not a timer (widget tests check for pending timers).
        await Future<void>.value();
      }
      if (!cancelled) await controller.close();
    }());
    return controller.stream.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  Object? noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}
