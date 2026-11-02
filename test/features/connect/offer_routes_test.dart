import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/features/connect/data/accept_gate.dart';
import 'package:kfm/features/connect/data/client_session_store.dart';
import 'package:kfm/features/connect/data/known_devices_dao.dart';
import 'package:kfm/features/connect/data/middleware/allow_list.dart';
import 'package:kfm/features/connect/data/middleware/authenticate.dart';
import 'package:kfm/features/connect/data/offer_service.dart';
import 'package:kfm/features/connect/data/routes/offer_routes.dart';
import 'package:kfm/features/connect/data/routes/pair_routes.dart';
import 'package:kfm/features/connect/data/routes/roots_routes.dart';
import 'package:kfm/features/connect/data/routes/upload_routes.dart';
import 'package:kfm/features/connect/data/server_pipeline.dart';
import 'package:kfm/features/connect/data/share_offers_dao.dart';
import 'package:kfm/features/connect/data/share_scope_store.dart';
import 'package:kfm/features/connect/data/share_server.dart';
import 'package:kfm/features/connect/data/upload_store.dart';
import 'package:kfm/features/connect/domain/connection_request.dart';
import 'package:kfm/features/connect/domain/known_device.dart';
import 'package:kfm/features/connect/domain/offer_protocol.dart';
import 'package:kfm/features/connect/domain/protocol.dart';
import 'package:kfm/features/connect/domain/share_offer.dart';
import 'package:kfm/features/connect/domain/share_scope.dart';
import 'package:kfm/features/connect/domain/upload_protocol.dart';
import 'package:shelf/shelf.dart';

import '../../core/files/fake_file_source.dart';
import 'handler_remote_http.dart';
import 'path_guard_test.dart' show fakeGuard;

const _root = '/storage/emulated/0';
const _downloads = '$_root/Download';
final String _fpS = 'aa' * 32;
final String _fpOther = 'bb' * 32;

String _hex(int n) => n.toRadixString(16).padLeft(32, '0');

/// TASK-N12 receiver side: send-only sessions, offers, grants and the
/// upload hooks, through the real pipeline.
void main() {
  late AppDatabase db;
  late DbWriteQueue queue;
  late ClientSessionStore sessions;
  late ShareScopeStore scopes;
  late FakeFileSource files;
  late UploadStore uploads;
  late Directory staging;
  late KnownDevicesRepository devices;
  late OfferRepository offers;
  late OfferService service;
  late Handler handler;
  late IssuedSession sender;
  late IssuedSession other;
  late DateTime now;

  OfferService newService() => OfferService(
    repo: offers,
    devices: devices,
    sessions: () => sessions,
    uploads: uploads,
    freeBytes: (_) async => files.freeBytesValue,
    downloadsRoot: _downloads,
    clock: () => now,
  );

  Handler build(OfferService s) {
    final guard = AllowListGuard(
      scopeOf: scopes.scopeOf,
      source: () => files,
      paths: fakeGuard(existing: {_root, '$_root/DCIM', _downloads}),
      grants: s,
    );
    return buildSharePipeline(
      served: [LocalAddress(InternetAddress('192.168.1.23'), 24, 'wlan0')],
      authenticate: authenticate(sessions),
      sizeLimitExempt: (r) =>
          isUploadChunkRequest(r) || isOfferCreateRequest(r),
      routes: [
        rootsRoute(scopes),
        ...offerRoutes(() => s),
        ...uploadRoutes(
          UploadRoutesEnv(
            guard: guard,
            sessions: sessions,
            uploads: uploads,
            source: () => files,
            addToIndex: (_) async {},
            stagingFreeBytes: () async => null,
            grants: s,
          ),
        ),
      ],
    );
  }

  setUp(() async {
    now = DateTime(2026, 11, 2, 12);
    db = AppDatabase(NativeDatabase.memory());
    queue = DbWriteQueue();
    staging = await Directory.systemTemp.createTemp('kfm_offers');
    sessions = ClientSessionStore();
    scopes = ShareScopeStore(sessions: sessions);
    files = FakeFileSource()
      ..addFolder('$_root/DCIM')
      ..addFolder(_downloads);
    uploads = UploadStore(staging: () async => staging);
    devices = KnownDevicesRepository(KnownDevicesDao(db), queue);
    offers = OfferRepository(ShareOffersDao(db), queue);
    service = newService();
    handler = build(service);
    sender = sessions.issue(
      clientFingerprint: _fpS,
      clientDeviceId: 'd',
      clientName: 'Pixel',
      purpose: SessionPurpose.send,
    );
    other = sessions.issue(
      clientFingerprint: _fpOther,
      clientDeviceId: 'd2',
      clientName: 'PC',
    );
  });

  tearDown(() async {
    service.dispose();
    sessions.clear();
    await files.dispose();
    await queue.close();
    await db.close();
    if (await staging.exists()) await staging.delete(recursive: true);
  });

  Future<Response> call(
    String method,
    String path, {
    Object? json,
    List<int>? bytes,
    IssuedSession? as,
  }) => Future.value(
    handler(
      Request(
        method,
        Uri.parse('https://192.168.1.23:4433$path'),
        headers: {
          'authorization': 'Bearer ${(as ?? sender).token}',
          if (json != null) 'content-type': 'application/json',
          if (bytes != null) 'content-length': '${bytes.length}',
        },
        body: json != null ? jsonEncode(json) : bytes,
        context: {
          'shelf.io.connection_info': FakeConnectionInfo('192.168.1.40'),
        },
      ),
    ),
  );

  Future<Map<String, Object?>> body(Response r) async {
    final text = await r.readAsString();
    return text.isEmpty ? const {} : jsonDecode(text) as Map<String, Object?>;
  }

  Future<String?> code(Response r) async => (await body(r))['code'] as String?;

  Map<String, Object?> offer(String id, List<(String, int)> f) =>
      CreateOfferDto(
        offerId: id,
        files: [for (final (n, s) in f) OfferFileDto(name: n, size: s)],
      ).toJson();

  Future<OfferDto> create(
    String id, [
    List<(String, int)> f = const [('a.jpg', 3)],
    IssuedSession? as,
  ]) async {
    final r = await call('POST', ApiRoutes.offers, json: offer(id, f), as: as);
    final text = await r.readAsString();
    expect(r.statusCode, anyOf(200, 201), reason: text);
    return OfferDto.fromJson(jsonDecode(text) as Map<String, Object?>);
  }

  Map<String, Object?> up(
    String uploadId,
    String rootId,
    String name,
    int size, {
    String path = '',
  }) => CreateUploadDto(
    uploadId: uploadId,
    rootId: rootId,
    path: path,
    name: name,
    size: size,
  ).toJson();

  /// One whole upload of [bytes] as [name] into [rootId].
  Future<Response> send(
    String uploadId,
    String rootId,
    String name,
    List<int> bytes, {
    IssuedSession? as,
  }) async {
    var r = await call(
      'POST',
      ApiRoutes.uploads,
      json: up(uploadId, rootId, name, bytes.length),
      as: as,
    );
    if (r.statusCode != 201) return r;
    r = await call(
      'PUT',
      '${ApiRoutes.uploadChunk(uploadId)}?offset=0',
      bytes: bytes,
      as: as,
    );
    if (r.statusCode != 200) return r;
    return await call(
      'POST',
      ApiRoutes.uploadComplete(uploadId),
      json: const {},
      as: as,
    );
  }

  group('send-only sessions', () {
    test(
      'pairing with purpose send: no prompt, no seeding, roots []',
      () async {
        final gate = AcceptGate();
        var seeded = false;
        final store = ClientSessionStore();
        final handOff = promptHandOff(
          gate: gate,
          sessions: store,
          serverDeviceId: () async => 'srv',
          roots: (_) => const [
            RootDto(id: 'cam', label: 'DCIM', readOnly: false),
          ],
          beforeIssue: (_) async => seeded = true,
        );
        final events = <Object>[];
        final sub = gate.events.listen(events.add);
        for (final method in PairMethod.values) {
          final r = await handOff(
            PairCandidate(
              hello: const ClientHelloDto(
                pairAttemptId: 'p',
                clientDeviceId: 'd',
                clientName: 'Pixel',
                clientPlatform: 'android',
                clientCertPem: 'pem',
                purpose: 'send',
              ),
              clientFingerprint: _fpS,
              remoteIp: '192.168.1.40',
              method: method,
              serverFingerprint: 'cd' * 32,
            ),
          );
          expect(r.statusCode, 200);
          final dto = PairAcceptedDto.fromJson(
            jsonDecode(await r.readAsString()) as Map<String, Object?>,
          );
          expect(dto.roots, isEmpty);
          expect(store.sessions.single.sendOnly, isTrue);
        }
        await Future<void>.delayed(Duration.zero);
        expect(events, isEmpty);
        expect(gate.pending, isNull);
        expect(seeded, isFalse);
        await sub.cancel();
        store.clear();
      },
    );

    test('the hello purpose is optional on the wire (missing = connect)', () {
      const hello = ClientHelloDto(
        pairAttemptId: 'p',
        clientDeviceId: 'd',
        clientName: 'n',
        clientPlatform: 'android',
        clientCertPem: 'pem',
      );
      expect(hello.toJson().containsKey('purpose'), isFalse);
      expect(ClientHelloDto.fromJson(hello.toJson()).sendOnly, isFalse);
      final send = ClientHelloDto.fromJson({
        ...hello.toJson(),
        'purpose': 'send',
      });
      expect(send.sendOnly, isTrue);
      expect(
        ClientHelloDto.fromJson({...hello.toJson(), 'purpose': 'x'}).sendOnly,
        isFalse,
      );
    });

    test('a send session reaches no folder even with a stored scope', () async {
      const scope = ShareScope([
        SharedRoot(
          id: 'cam',
          path: '$_root/DCIM',
          label: 'DCIM',
          readOnly: false,
        ),
      ]);
      scopes
        ..set(_fpS, scope)
        ..set(_fpOther, scope);
      final roots = await call('GET', ApiRoutes.roots);
      expect(await body(roots), {'roots': <Object?>[]});
      final r = await call(
        'POST',
        ApiRoutes.uploads,
        json: up(_hex(1), 'cam', 'a.jpg', 3),
      );
      expect(r.statusCode, 403);
      // The same scope works for a normal session.
      final ok = await call(
        'POST',
        ApiRoutes.uploads,
        json: up(_hex(2), 'cam', 'a.jpg', 3),
        as: other,
      );
      expect(ok.statusCode, 201);
    });
  });

  group('offers', () {
    test('create → pending; repeat is idempotent; others get 404', () async {
      final id = _hex(10);
      final first = await create(id, [('a.jpg', 3), ('b.mp4', 5)]);
      expect(first.status, OfferWireStatus.pending);
      expect(first.expiresInSeconds, 120);
      expect(service.prompts.single.offer.fileCount, 2);
      final again = await create(id, [('a.jpg', 3), ('b.mp4', 5)]);
      expect(again.status, OfferWireStatus.pending);
      expect(service.prompts, hasLength(1));
      final peek = await call('GET', ApiRoutes.offer(id), as: other);
      expect(peek.statusCode, 404);
      final steal = await call(
        'POST',
        ApiRoutes.offers,
        json: offer(id, [('a.jpg', 3)]),
        as: other,
      );
      expect(steal.statusCode, 404);
    });

    test('limits: 2nd pending 409, bad names 400, 501 files 400', () async {
      await create(_hex(20));
      final second = await call(
        'POST',
        ApiRoutes.offers,
        json: offer(_hex(21), [('a.jpg', 1)]),
      );
      expect(second.statusCode, 409);
      for (final bad in ['../x', '.nomedia', 'a\u0001b', 'x' * 300, 'a/b']) {
        final r = await call(
          'POST',
          ApiRoutes.offers,
          json: offer(_hex(22), [(bad, 1)]),
          as: other,
        );
        expect(r.statusCode, 400, reason: bad);
        expect(await code(r), 'invalid_name');
      }
      final many = await call(
        'POST',
        ApiRoutes.offers,
        json: offer(_hex(23), [for (var i = 0; i < 501; i++) ('f$i.jpg', 1)]),
        as: other,
      );
      expect(many.statusCode, 400);
      final negative = await call(
        'POST',
        ApiRoutes.offers,
        json: {
          'offerId': _hex(24),
          'files': [
            {'name': 'a.jpg', 'size': -1},
          ],
        },
        as: other,
      );
      expect(negative.statusCode, 400);
    });

    test('6 offers in a minute → 429', () async {
      for (var i = 0; i < 5; i++) {
        await create(_hex(30 + i));
        final d = await call('DELETE', ApiRoutes.offer(_hex(30 + i)));
        expect(d.statusCode, 200);
      }
      final r = await call(
        'POST',
        ApiRoutes.offers,
        json: offer(_hex(40), [('a.jpg', 1)]),
      );
      expect(r.statusCode, 429);
      now = now.add(const Duration(minutes: 2));
      expect((await create(_hex(41))).status, OfferWireStatus.pending);
    });

    test('3 declines in a row → 10 minute cooldown', () async {
      for (var i = 0; i < 3; i++) {
        await create(_hex(50 + i));
        expect(await service.decide(_hex(50 + i), accept: false), isTrue);
      }
      final r = await call(
        'POST',
        ApiRoutes.offers,
        json: offer(_hex(60), [('a.jpg', 1)]),
      );
      expect(r.statusCode, 429);
      now = now.add(const Duration(minutes: 11));
      expect((await create(_hex(61))).status, OfferWireStatus.pending);
    });

    test('not enough space: declined noSpace at once, no prompt', () async {
      files.freeBytesValue = 10;
      final dto = await create(_hex(70), [('big.mp4', 1 << 30)]);
      expect(dto.status, OfferWireStatus.declined);
      expect(dto.reason, OfferDeclineReason.noSpace);
      expect(service.prompts, isEmpty);
    });

    test('no answer for 2 minutes → expired; a later upload → 403', () async {
      final id = _hex(80);
      await create(id);
      now = now.add(const Duration(minutes: 2, seconds: 1));
      final s = await call('GET', ApiRoutes.offer(id));
      expect(OfferDto.fromJson(await body(s)).status, OfferWireStatus.expired);
      expect(await service.decide(id, accept: true), isFalse);
      final r = await send(_hex(81), offerRootId(id), 'a.jpg', [1, 2, 3]);
      expect(r.statusCode, 403);
      expect(service.prompts, isEmpty);
    });

    test(
      'accept → 3 uploads land in Download/<S>; same names get (1)',
      () async {
        final id = _hex(90);
        await create(id, [('a.jpg', 3), ('a.jpg', 2), ('c.txt', 1)]);
        expect(await service.decide(id, accept: true), isTrue);
        final s = OfferDto.fromJson(
          await body(await call('GET', ApiRoutes.offer(id))),
        );
        expect(s.status, OfferWireStatus.accepted);
        expect(s.rootId, offerRootId(id));
        final events = <OfferEvent>[];
        final sub = service.events.listen(events.add);
        expect(
          (await send(_hex(91), offerRootId(id), 'a.jpg', [
            1,
            2,
            3,
          ])).statusCode,
          200,
        );
        expect(
          (await send(_hex(92), offerRootId(id), 'a.jpg', [4, 5])).statusCode,
          200,
        );
        expect(
          (await send(_hex(93), offerRootId(id), 'c.txt', [6])).statusCode,
          200,
        );
        expect(await files.stat('path:$_downloads/Pixel/a.jpg'), isNotNull);
        expect(await files.stat('path:$_downloads/Pixel/a (1).jpg'), isNotNull);
        expect(await files.stat('path:$_downloads/Pixel/c.txt'), isNotNull);
        final done = OfferDto.fromJson(
          await body(await call('GET', ApiRoutes.offer(id))),
        );
        expect(done.status, OfferWireStatus.done);
        await Future<void>.delayed(Duration.zero);
        expect(events.single, isA<OfferReceived>());
        expect(
          staging.listSync().where((e) => e.path.endsWith('.part')),
          isEmpty,
        );
        await sub.cancel();
      },
    );

    test('uploads that were not offered are refused', () async {
      final id = _hex(100);
      await create(id, [('a.jpg', 3)]);
      // Not accepted yet.
      expect(
        (await send(_hex(101), offerRootId(id), 'a.jpg', [1, 2, 3])).statusCode,
        403,
      );
      await service.decide(id, accept: true);
      // Another client's offer root.
      expect(
        (await send(_hex(102), offerRootId(id), 'a.jpg', [
          1,
          2,
          3,
        ], as: other)).statusCode,
        403,
      );
      // A sub-path.
      final sub = await call(
        'POST',
        ApiRoutes.uploads,
        json: up(_hex(103), offerRootId(id), 'a.jpg', 3, path: 'x'),
      );
      expect(sub.statusCode, 403);
      // A name that wasn't offered, a size above offered + 1 MiB.
      final wrongName = await call(
        'POST',
        ApiRoutes.uploads,
        json: up(_hex(104), offerRootId(id), 'b.jpg', 3),
      );
      expect(wrongName.statusCode, 409);
      final tooBig = await call(
        'POST',
        ApiRoutes.uploads,
        json: up(
          _hex(105),
          offerRootId(id),
          'a.jpg',
          3 + kOfferSizeSlackBytes + 1,
        ),
      );
      expect(tooBig.statusCode, 409);
      // The offered one; a second file of the same name isn't offered.
      expect(
        (await send(_hex(106), offerRootId(id), 'a.jpg', [1, 2, 3])).statusCode,
        200,
      );
      final extra = await call(
        'POST',
        ApiRoutes.uploads,
        json: up(_hex(107), offerRootId(id), 'a.jpg', 3),
      );
      expect(extra.statusCode, 403); // the offer is done: no grant
      expect(
        files.calls.where((c) => c.startsWith('importFile')),
        hasLength(1),
      );
    });

    test('receiver Stop mid-transfer: partial gone, next chunk 403', () async {
      final id = _hex(110);
      await create(id, [('a.jpg', 4)]);
      await service.decide(id, accept: true);
      var r = await call(
        'POST',
        ApiRoutes.uploads,
        json: up(_hex(111), offerRootId(id), 'a.jpg', 4),
      );
      expect(r.statusCode, 201);
      r = await call(
        'PUT',
        '${ApiRoutes.uploadChunk(_hex(111))}?offset=0',
        bytes: [1, 2],
      );
      expect(r.statusCode, 200);
      await service.stopByReceiver(id);
      r = await call(
        'PUT',
        '${ApiRoutes.uploadChunk(_hex(111))}?offset=2',
        bytes: [3, 4],
      );
      expect(r.statusCode, anyOf(403, 404));
      expect(
        staging.listSync().where((e) => e.path.endsWith('.part')),
        isEmpty,
      );
      final s = OfferDto.fromJson(
        await body(await call('GET', ApiRoutes.offer(id))),
      );
      expect(s.status, OfferWireStatus.cancelled);
    });

    test(
      'stop sharing: pending expire, accepted grants survive a restart',
      () async {
        final pending = _hex(120);
        final accepted = _hex(121);
        await create(accepted);
        await service.decide(accepted, accept: true);
        await create(pending, [('b.jpg', 1)]);
        await service.onStopSharing();
        expect(service.prompts, isEmpty);
        expect((await offers.dao.byId(pending))?.status, OfferStatus.expired);
        // A new service over the same rows (app restart).
        service.dispose();
        service = newService();
        handler = build(service);
        expect(
          await service.inboxRoot(_fpS, offerRootId(accepted)),
          isA<SharedRoot>(),
        );
        expect(
          (await send(_hex(122), offerRootId(accepted), 'a.jpg', [
            1,
            2,
            3,
          ])).statusCode,
          200,
        );
        // 7 days without activity end a grant.
        final idle = _hex(123);
        await create(idle, [('z.jpg', 1)]);
        await service.decide(idle, accept: true);
        now = now.add(const Duration(days: 8));
        expect(await service.inboxRoot(_fpS, offerRootId(idle)), isNull);
      },
    );

    test('auto-accept only for a non-temporary row with the flag', () async {
      Future<void> remember({required bool temporary, String fp = ''}) async {
        await devices.saveAfterPairing(
          PairedPeer(
            fingerprint: fp.isEmpty ? _fpS : fp,
            peerDeviceId: 'd',
            name: 'My Pixel',
            platform: 'android',
          ),
          temporary: temporary,
        );
        await devices.setAutoAcceptFiles(fp.isEmpty ? _fpS : fp, enabled: true);
      }

      await remember(temporary: true);
      expect((await create(_hex(130))).status, OfferWireStatus.pending);
      await service.decide(_hex(130), accept: false);
      await remember(temporary: false);
      final events = <OfferEvent>[];
      final sub = service.events.listen(events.add);
      final dto = await create(_hex(131));
      expect(dto.status, OfferWireStatus.accepted);
      expect(service.prompts, isEmpty);
      // Default folder from the remembered name.
      expect(
        (await service.inboxRoot(_fpS, offerRootId(_hex(131))))?.path,
        '$_downloads/My Pixel',
      );
      await Future<void>.delayed(Duration.zero);
      expect(events.single, isA<OfferAutoAccepted>());
      await sub.cancel();
    });

    test(
      'decide: remember + always accept write the row; excluded folder refused',
      () async {
        final id = _hex(140);
        await create(id);
        await expectLater(
          service.decide(
            id,
            accept: true,
            folder: '$_root/Android/data/com.other',
          ),
          throwsA(isA<OfferFolderRefused>()),
        );
        expect(
          await service.decide(id, accept: true, alwaysAccept: true),
          isTrue,
        );
        final row = await devices.byFingerprint(_fpS);
        expect(row?.isTemporary, isFalse);
        expect(row?.autoAcceptFiles, isTrue);
        expect(row?.autoAccept, isFalse);
      },
    );

    test('revoking the device ends its open offers', () async {
      final id = _hex(150);
      await create(id);
      await service.decide(id, accept: true);
      await service.revokeDevice(_fpS);
      expect(await service.inboxRoot(_fpS, offerRootId(id)), isNull);
    });
  });
}
