import 'dart:async';
import 'dart:io';
import 'dart:math';

/// A TCP proxy on loopback for network-chaos tests (TASK-Q1). It sits
/// between a client (e.g. `PinnedClient`) and a real server (e.g.
/// `ShareServer`) and forwards raw bytes, so TLS runs end to end through
/// it. Knobs apply to open and new connections at once:
/// - [refuse]: new connections are closed right after accept (a stopped
///   app / no route).
/// - [blackhole]: bytes in both directions are dropped silently; the
///   sockets stay open (Wi-Fi gone without a reset, AP isolation).
/// - [latency] per chunk and [bytesPerSecond] per direction.
/// - [cutDownstreamAfter] / [cutUpstreamAfter]: a connection is destroyed
///   once that many bytes went server→client / client→server through it
///   (the rest is never forwarded: a truncated response or request).
/// - [cutAll] drops every open connection now; [flap] repeats
///   cut + refuse for a while + accept again.
class ChaosProxy {
  new _(this._server, this.targetHost, this.targetPort);

  /// Listens on a free loopback port and forwards to [targetPort].
  static Future<ChaosProxy> start(
    int targetPort, {
    InternetAddress? targetHost,
  }) async {
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final proxy = ChaosProxy._(
      server,
      targetHost ?? InternetAddress.loopbackIPv4,
      targetPort,
    );
    proxy._sub = server.listen(proxy._accept);
    return proxy;
  }

  final ServerSocket _server;
  final InternetAddress targetHost;
  final int targetPort;
  late final StreamSubscription<Socket> _sub;
  final Set<_Link> _links = {};

  bool refuse = false;
  bool blackhole = false;
  Duration latency = Duration.zero;
  int? bytesPerSecond;
  int? cutDownstreamAfter;
  int? cutUpstreamAfter;

  /// Connections accepted (refused ones included) since the start.
  int accepted = 0;

  /// Bytes forwarded server→client in total.
  int downstreamBytes = 0;

  /// Bytes forwarded client→server in total.
  int upstreamBytes = 0;

  int get port => _server.port;

  /// Connections open right now (both legs alive).
  int get openConnections => _links.length;

  Uri uri([String scheme = 'https']) =>
      Uri(scheme: scheme, host: '127.0.0.1', port: port);

  /// Destroys every open connection (RST/FIN to both sides).
  void cutAll() {
    for (final l in _links.toList()) {
      l.destroy();
    }
  }

  /// Link down for [down] (open connections cut, new ones refused), then
  /// up again.
  Future<void> drop(Duration down) async {
    refuse = true;
    cutAll();
    await Future<void>.delayed(down);
    refuse = false;
  }

  /// [times] drops of [down] each, [up] apart.
  Future<void> flap({
    required int times,
    required Duration up,
    required Duration down,
  }) async {
    for (var i = 0; i < times; i++) {
      await Future<void>.delayed(up);
      await drop(down);
    }
  }

  Future<void> close() async {
    await _sub.cancel();
    await _server.close();
    cutAll();
  }

  Future<void> _accept(Socket client) async {
    accepted++;
    if (refuse) {
      client.destroy();
      return;
    }
    final Socket upstream;
    try {
      upstream = await Socket.connect(
        targetHost,
        targetPort,
        timeout: const Duration(seconds: 5),
      );
    } on Object {
      client.destroy();
      return;
    }
    if (refuse) {
      client.destroy();
      upstream.destroy();
      return;
    }
    final link = _Link(this, client, upstream);
    _links.add(link);
    link.start();
  }
}

/// One proxied connection: client ⇄ upstream.
class _Link {
  new(this._proxy, this._client, this._upstream);

  final ChaosProxy _proxy;
  final Socket _client;
  final Socket _upstream;
  int _down = 0;
  int _up = 0;
  bool _dead = false;
  final List<StreamSubscription<List<int>>> _subs = [];

  void start() {
    _subs
      ..add(_pipe(_client, _upstream, downstream: false))
      ..add(_pipe(_upstream, _client, downstream: true));
  }

  StreamSubscription<List<int>> _pipe(
    Socket from,
    Socket to, {
    required bool downstream,
  }) {
    var queue = Future<void>.value();
    // Cancelled in destroy() (kept in _subs).
    // ignore: cancel_subscriptions
    late final StreamSubscription<List<int>> sub;
    return sub = from.listen(
      (chunk) {
        sub.pause();
        queue = queue.then((_) => _forward(chunk, to, downstream)).then((_) {
          if (!_dead) sub.resume();
        }, onError: (Object _) => destroy());
      },
      onError: (Object _) => destroy(),
      onDone: () => queue.whenComplete(destroy),
      cancelOnError: true,
    );
  }

  Future<void> _forward(List<int> chunk, Socket to, bool downstream) async {
    if (_dead) return;
    final p = _proxy;
    if (p.latency > Duration.zero) await Future<void>.delayed(p.latency);
    final rate = p.bytesPerSecond;
    if (rate != null && rate > 0) {
      await Future<void>.delayed(
        Duration(microseconds: chunk.length * 1000000 ~/ rate),
      );
    }
    if (_dead || p.blackhole) return;
    final limit = downstream ? p.cutDownstreamAfter : p.cutUpstreamAfter;
    final sent = downstream ? _down : _up;
    var out = chunk;
    var cut = false;
    if (limit != null && sent + chunk.length >= limit) {
      out = chunk.sublist(0, max(0, limit - sent));
      cut = true;
    }
    if (out.isNotEmpty) {
      to.add(out);
      if (downstream) {
        _down += out.length;
        p.downstreamBytes += out.length;
      } else {
        _up += out.length;
        p.upstreamBytes += out.length;
      }
      try {
        await to.flush();
      } on Object {
        destroy();
        return;
      }
    }
    if (cut) destroy();
  }

  void destroy() {
    if (_dead) return;
    _dead = true;
    _proxy._links.remove(this);
    for (final s in _subs) {
      unawaited(s.cancel());
    }
    _client.destroy();
    _upstream.destroy();
  }
}
