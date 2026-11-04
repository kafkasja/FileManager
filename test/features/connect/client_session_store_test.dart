import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/features/connect/data/client_session_store.dart';
import 'package:kfm/features/connect/domain/connection_request.dart';

void main() {
  late DateTime now;
  late ClientSessionStore store;

  setUp(() {
    now = DateTime(2026, 11);
    store = ClientSessionStore(clock: () => now);
  });

  tearDown(() => store.clear());

  IssuedSession issue([String fp = 'fp-b', String name = 'Phone B']) =>
      store.issue(
        clientFingerprint: fp,
        clientDeviceId: 'dev-$fp',
        clientName: name,
      );

  test('issue: 32-byte base64url token, only its hash is kept', () {
    final s = issue();
    expect(s.token, hasLength(43)); // 32 bytes, no padding
    expect(s.token, matches(RegExp(r'^[A-Za-z0-9_\-]+$')));
    expect(s.session.tokenHash, ClientSessionStore.hashToken(s.token));
    expect(s.session.tokenHash, isNot(contains(s.token)));
    expect(store.sessions.single.clientName, 'Phone B');
  });

  test('verify: right token, wrong token, touches lastUsedAt', () {
    final s = issue();
    now = now.add(const Duration(minutes: 3));
    final v = store.verify(s.token);
    expect(v?.sessionId, s.session.sessionId);
    expect(v?.lastUsedAt, now);
    expect(store.verify('${s.token}x'), isNull);
    expect(store.verify(''), isNull);
  });

  test('idle 10 minutes → expired; activity keeps it alive', () {
    final s = issue();
    now = now.add(const Duration(minutes: 9));
    expect(store.verify(s.token), isNotNull);
    now = now.add(const Duration(minutes: 9));
    expect(store.verify(s.token), isNotNull);
    now = now.add(const Duration(minutes: 10));
    expect(store.verify(s.token), isNull);
    expect(store.sessions, isEmpty);
  });

  test('sessions getter drops idle sessions too', () {
    issue();
    now = now.add(const Duration(minutes: 10));
    expect(store.sessions, isEmpty);
  });

  test('a second accept of the same fingerprint replaces the session', () {
    final first = issue();
    final second = issue();
    expect(store.verify(first.token), isNull);
    expect(store.verify(second.token), isNotNull);
    expect(store.sessions, hasLength(1));
  });

  test('several clients each get their own session', () {
    final b = issue('fp-b', 'B');
    final c = issue('fp-c', 'C');
    expect(store.sessions.map((s) => s.clientName), ['B', 'C']);
    expect(store.revoke(b.session.sessionId), isTrue);
    expect(store.verify(b.token), isNull);
    expect(store.verify(c.token), isNotNull);
  });

  test('revokeByFingerprint and clear', () {
    final b = issue();
    final c = issue('fp-c');
    expect(store.revokeByFingerprint('fp-b'), isTrue);
    expect(store.revokeByFingerprint('fp-b'), isFalse);
    expect(store.verify(b.token), isNull);
    store.clear();
    expect(store.verify(c.token), isNull);
    expect(store.sessions, isEmpty);
  });

  test('revoking cancels the session’s tracked streams', () async {
    final s = issue();
    var cancelled = 0;
    final controller = StreamController<int>(onCancel: () => cancelled++);
    store.registerStream(
      s.session.sessionId,
      controller.stream.listen((_) {}),
      canonicalPath: '/sdcard/DCIM/a.jpg',
    );
    expect(
      store.streamsOf(s.session.sessionId).single.canonicalPath,
      '/sdcard/DCIM/a.jpg',
    );
    store.revoke(s.session.sessionId);
    await pumpEventQueue();
    expect(cancelled, 1);
    expect(store.streamsOf(s.session.sessionId), isEmpty);
  });

  test('unregistered streams are not cancelled; unknown session → '
      'cancelled at once', () async {
    final s = issue();
    var cancelled = 0;
    final a = StreamController<int>(onCancel: () => cancelled++);
    store.registerStream(s.session.sessionId, a.stream.listen((_) {}))();
    store.revoke(s.session.sessionId);
    await pumpEventQueue();
    expect(cancelled, 0);
    final b = StreamController<int>(onCancel: () => cancelled++);
    store.registerStream('gone', b.stream.listen((_) {}));
    await pumpEventQueue();
    expect(cancelled, 1);
    await a.close();
  });

  test('changes emit on add and remove, not on touch', () async {
    final seen = <List<ClientSession>>[];
    final sub = store.changes.listen(seen.add);
    final s = issue();
    store
      ..verify(s.token)
      ..revoke(s.session.sessionId);
    await pumpEventQueue();
    expect(seen.map((l) => l.length), [1, 0]);
    unawaited(sub.cancel());
  });

  test('Q8: no request for 20 s (3 missed heartbeats) → unresponsive and '
      'the list emits again; a request brings it back; a running stream '
      'keeps it responsive', () {
    fakeAsync((async) {
      final s = issue();
      final emitted = <List<ClientSession>>[];
      final sub = store.changes.listen(emitted.add);
      expect(store.isResponsive(s.session), isTrue);
      now = now.add(const Duration(seconds: 15));
      async.elapse(const Duration(seconds: 5));
      expect(store.isResponsive(s.session), isTrue);
      expect(emitted, isEmpty);
      now = now.add(const Duration(seconds: 10));
      async.elapse(const Duration(seconds: 5));
      expect(store.isResponsive(s.session), isFalse);
      expect(emitted, hasLength(1), reason: 'shown as disconnected');
      // The session itself is still valid (it may come back).
      expect(store.sessions, hasLength(1));
      expect(store.verify(s.token), isNotNull);
      expect(store.isResponsive(s.session), isTrue);
      async.flushMicrotasks();
      expect(emitted, hasLength(2), reason: 'connected again');

      // A long download: no heartbeat needed while its stream runs.
      final c = StreamController<int>();
      final unregister = store.registerStream(
        s.session.sessionId,
        c.stream.listen((_) {}),
      );
      now = now.add(const Duration(minutes: 1));
      async.elapse(const Duration(seconds: 5));
      expect(store.isResponsive(s.session), isTrue);
      expect(store.hasActiveStreams, isTrue);
      unregister();
      expect(store.hasActiveStreams, isFalse);
      async.elapse(const Duration(seconds: 5));
      expect(store.isResponsive(s.session), isFalse);
      unawaited(sub.cancel());
      unawaited(c.close());
      store.clear();
      async.flushTimers();
    });
  });
}
