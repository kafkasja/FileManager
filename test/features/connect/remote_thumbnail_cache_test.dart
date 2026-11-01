import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/features/connect/ui/remote_thumbnail_provider.dart';

import 'fake_remote_http.dart';

Uint8List _bytes(int n) => Uint8List(n);

void main() {
  test('keeps at most 300 entries by default, evicting the oldest', () {
    final cache = RemoteThumbnailCache();
    for (var i = 0; i < 301; i++) {
      cache.put('k$i', _bytes(10));
    }
    expect(cache.length, 300);
    expect(cache.get('k0'), isNull);
    expect(cache.get('k1'), isNotNull);
    expect(cache.get('k300'), isNotNull);
    expect(cache.bytes, 3000);
  });

  test('evicts by bytes and skips values over the byte limit', () {
    final cache = RemoteThumbnailCache(maxBytes: 100)
      ..put('a', _bytes(40))
      ..put('b', _bytes(40))
      ..put('c', _bytes(40));
    expect(cache.get('a'), isNull);
    expect(cache.length, 2);
    expect(cache.bytes, 80);
    cache.put('huge', _bytes(101));
    expect(cache.get('huge'), isNull);
    expect(cache.bytes, 80);
    // Replacing a key adjusts the byte count.
    cache.put('b', _bytes(10));
    expect(cache.bytes, 50);
  });

  test('default byte limit is 30 MB', () {
    final cache = RemoteThumbnailCache();
    for (var i = 0; i < 31; i++) {
      cache.put('k$i', _bytes(1 << 20));
    }
    expect(cache.bytes, 30 << 20);
    expect(cache.get('k0'), isNull);
  });

  test('get marks an entry as recently used', () {
    final cache = RemoteThumbnailCache(maxEntries: 2)
      ..put('a', _bytes(1))
      ..put('b', _bytes(1));
    expect(cache.get('a'), isNotNull);
    cache.put('c', _bytes(1));
    expect(cache.get('b'), isNull);
    expect(cache.get('a'), isNotNull);
    expect(cache.get('c'), isNotNull);
  });

  test('clear empties the cache', () {
    final cache = RemoteThumbnailCache()
      ..put('a', _bytes(5))
      ..put('b', _bytes(5))
      ..clear();
    expect(cache.length, 0);
    expect(cache.bytes, 0);
    expect(cache.get('a'), isNull);
  });

  test('provider equality ignores http and cache, differs by epoch', () {
    RemoteThumbnailProvider p({int epoch = 1, String id = 'ms:1'}) =>
        RemoteThumbnailProvider(
          http: FakeRemoteHttp(),
          cache: RemoteThumbnailCache(),
          peerFingerprint: 'fp',
          serverId: id,
          epoch: epoch,
        );
    expect(p(), p());
    expect(p().hashCode, p().hashCode);
    expect(p(), isNot(p(epoch: 2)));
    expect(p(), isNot(p(id: 'ms:2')));
  });
}
