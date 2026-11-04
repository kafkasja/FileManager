import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:typed_data';

/// A connection must deliver its first request's headers within this long
/// (TLS handshake included), or it is closed (Q7: slowloris and never-TLS
/// sockets held file descriptors forever).
const Duration kFirstRequestTimeout = Duration(seconds: 15);

/// At most this many connections may wait for their first request at once;
/// newer ones are closed right away (a LAN peer opening sockets in a loop).
const int kMaxPendingConnections = 128;

/// The share server's listening socket (Q7 follow-up): plain TCP accepted
/// here, TLS done per connection with [SecurityContext], and a watchdog per
/// connection until [HttpServer] hands its first request out
/// ([firstRequest]). dart:io's `idleTimeout` only covers the gaps between
/// requests, so before the first one nothing else ends a silent socket.
/// Running requests (long downloads / uploads) are never touched: the
/// watchdog ends with the first request's headers.
class GuardedServerSocket extends StreamView<Socket> implements ServerSocket {
  new _(
    this._raw,
    this._controller, {
    required this.firstRequestTimeout,
    required this.maxPending,
  }) : super(_controller.stream);

  static Future<GuardedServerSocket> bind(
    InternetAddress address,
    int port,
    SecurityContext context, {
    Duration firstRequestTimeout = kFirstRequestTimeout,
    int maxPending = kMaxPendingConnections,
  }) async {
    final raw = await ServerSocket.bind(address, port);
    return GuardedServerSocket._(
      raw,
      StreamController<Socket>(),
      firstRequestTimeout: firstRequestTimeout,
      maxPending: maxPending,
    ).._accept(context);
  }

  final ServerSocket _raw;
  final StreamController<Socket> _controller;
  final Duration firstRequestTimeout;
  final int maxPending;

  /// Raw sockets without a first request yet, by `address:port` of the
  /// peer (what `HttpRequest.connectionInfo` reports).
  final Map<String, _Pending> _pending = {};
  StreamSubscription<Socket>? _sub;

  /// Connections still waiting for their first request.
  int get pendingCount => _pending.length;

  @override
  int get port => _raw.port;

  @override
  InternetAddress get address => _raw.address;

  void _accept(SecurityContext context) {
    _sub = _raw.listen(
      (raw) => _onConnection(raw, context),
      onError: (Object e) =>
          developer.log('accept failed: ${e.runtimeType}', name: 'kfm.connect'),
    );
  }

  void _onConnection(Socket raw, SecurityContext context) {
    final String key;
    try {
      key = _key(raw.remoteAddress, raw.remotePort);
    } on SocketException {
      raw.destroy(); // already gone
      return;
    }
    if (_pending.length >= maxPending || _pending.containsKey(key)) {
      raw.destroy();
      return;
    }
    final p = _Pending(raw.destroy);
    _pending[key] = p;
    p.timer = Timer(firstRequestTimeout, () => _drop(key));
    // The first bytes (the ClientHello) are read here so a socket that
    // never starts TLS can still be closed; once handed to the TLS layer
    // the plain socket can't be closed any more, so a handshake that
    // stalls is closed as soon as it ends (or fails).
    var handedOver = false;
    // Ends with the socket (destroyed here, or handed to the TLS layer).
    // ignore: cancel_subscriptions
    late final StreamSubscription<Uint8List> sub;
    sub = raw.listen(
      (first) {
        if (handedOver) return;
        handedOver = true;
        sub.pause();
        p.kill = null;
        unawaited(
          SecureSocket.secureServer(
            raw,
            context,
            bufferedData: first,
          ).then<void>(
            (secure) {
              if (!identical(_pending[key], p) || _controller.isClosed) {
                secure.destroy();
                return;
              }
              p.kill = secure.destroy;
              _controller.add(secure);
            },
            // Bad TLS, or the peer went.
            onError: (Object e) => _drop(key),
          ),
        );
      },
      onError: (Object e) {
        if (!handedOver) _drop(key);
      },
      onDone: () {
        if (!handedOver) _drop(key);
      },
    );
  }

  /// The connection of [info] delivered its first request: no watchdog any
  /// more (dart:io's idle timeout takes over between requests).
  void firstRequest(HttpConnectionInfo? info) {
    if (info == null) return;
    _pending.remove(_key(info.remoteAddress, info.remotePort))?.timer?.cancel();
  }

  void _drop(String key) {
    final p = _pending.remove(key);
    p?.timer?.cancel();
    p?.kill?.call();
  }

  static String _key(InternetAddress a, int port) => '${a.address}:$port';

  /// Stops accepting and closes every connection still without a request
  /// (the [HttpServer] closes the others).
  @override
  Future<ServerSocket> close() async {
    await _sub?.cancel();
    _pending.keys.toList().forEach(_drop);
    await _raw.close();
    if (!_controller.isClosed) await _controller.close();
    return this;
  }
}

/// One connection without its first request yet.
class _Pending {
  new(this.kill);

  /// Closes it: the plain socket before TLS, the TLS socket after; null
  /// while the TLS layer owns it mid-handshake.
  void Function()? kill;
  Timer? timer;
}
