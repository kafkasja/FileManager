import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/features/connect/data/pair_nonce_store.dart';
import 'package:kfm/features/connect/domain/protocol.dart';

void main() {
  var now = DateTime.utc(2026, 11);
  late PairNonceStore store;

  setUp(() {
    now = DateTime.utc(2026, 11);
    store = PairNonceStore(clock: () => now);
  });

  test('32 random bytes, single use', () {
    final n = store.issue('192.168.1.5');
    expect(n, hasLength(32));
    expect(store.issue('192.168.1.5'), isNot(n));
    expect(store.consume('192.168.1.5', n), isTrue);
    expect(store.consume('192.168.1.5', n), isFalse);
  });

  test('a failed use still consumes it (wrong IP)', () {
    final n = store.issue('192.168.1.5');
    expect(store.consume('192.168.1.6', n), isFalse);
    expect(store.consume('192.168.1.5', n), isFalse);
  });

  test('expires after 60 s', () {
    final a = store.issue('ip');
    final b = store.issue('ip');
    now = now.add(const Duration(seconds: 59));
    expect(store.consume('ip', a), isTrue);
    now = now.add(const Duration(seconds: 1));
    expect(store.consume('ip', b), isFalse);
    expect(store.length, 0);
  });

  test('at most 8 per IP: the oldest is evicted', () {
    final first = store.issue('ip');
    final rest = [for (var i = 0; i < kPairNoncesPerIp; i++) store.issue('ip')];
    expect(store.length, kPairNoncesPerIp);
    expect(store.consume('ip', first), isFalse);
    expect(store.consume('ip', rest.last), isTrue);
  });

  test('at most 64 in total: the oldest is evicted', () {
    final first = store.issue('ip-0');
    for (var i = 1; i <= kPairNoncesTotal; i++) {
      store.issue('ip-$i');
    }
    expect(store.length, kPairNoncesTotal);
    expect(store.consume('ip-0', first), isFalse);
  });

  test('clear forgets everything', () {
    final n = store.issue('ip');
    store.clear();
    expect(store.consume('ip', n), isFalse);
  });
}
