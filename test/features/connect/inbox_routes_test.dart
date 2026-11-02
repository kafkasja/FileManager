import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/features/connect/data/client_session_store.dart';
import 'package:kfm/features/connect/data/known_devices_dao.dart';
import 'package:kfm/features/connect/data/middleware/allow_list.dart';
import 'package:kfm/features/connect/data/middleware/authenticate.dart';
import 'package:kfm/features/connect/data/offer_copy.dart';
import 'package:kfm/features/connect/data/offer_service.dart';
import 'package:kfm/features/connect/data/routes/inbox_routes.dart';
import 'package:kfm/features/connect/data/server_pipeline.dart';
import 'package:kfm/features/connect/data/share_offers_dao.dart';
import 'package:kfm/features/connect/data/share_scope_store.dart';
import 'package:kfm/features/connect/data/share_server.dart';
import 'package:kfm/features/connect/data/upload_store.dart';
import 'package:kfm/features/connect/domain/offer_protocol.dart';
import 'package:kfm/features/connect/domain/protocol.dart';
import 'package:kfm/features/connect/domain/share_offer.dart';
import 'package:kfm/features/transfers/domain/transfer_preprocessor.dart';
import 'package:shelf/shelf.dart';

import '../../core/files/fake_file_source.dart';
import 'handler_remote_http.dart' show FakeConnectionInfo;
import 'path_guard_test.dart' show fakeGuard;

const _root = '/storage/emulated/0';
final String _fpR = 'aa' * 32; // the client offers are made to
final String _fpOther = 'bb' * 32;

/// TASK-N12b: a sharing device offers files to a connected client.
void main() {
  late AppDatabase db;
  late DbWriteQueue queue;
  late ClientSessionStore sessions;
  late FakeFileSource files;
  late Directory staging;
  late OfferService service;
  late Handler handler;
  late AllowListGuard guard;
  late IssuedSession client;
  late IssuedSession other;
  late List<FileRef> picked;
  late DateTime now;
  var stripOn = false;

  setUp(() async {
    now = DateTime.now();
    stripOn = false;
    db = AppDatabase(NativeDatabase.memory());
    queue = DbWriteQueue();
    sessions = ClientSessionStore();
    files = FakeFileSource();
    picked = [
      files.addFile('$_root/DCIM/a.jpg', bytes: [1, 2, 3]),
      files.addFile('$_root/Docs/b.pdf', bytes: [4, 5]),
    ];
    files.addFile('$_root/DCIM/secret.jpg');
    staging = await Directory.systemTemp.createTemp('kfm_inbox');
    service = OfferService(
      repo: OfferRepository(ShareOffersDao(db), queue),
      devices: KnownDevicesRepository(KnownDevicesDao(db), queue),
      sessions: () => sessions,
      uploads: UploadStore(staging: () async => staging),
      freeBytes: (_) async => null,
      downloadsRoot: '$_root/Download',
      clock: () => now,
      ownName: () async => 'Tablet',
      staging: () async => staging,
      prepareCopy: (f, offerId, seq) => prepareOfferCopy(
        f,
        dir: () async => Directory('${staging.path}/offer-$offerId'),
        seq: seq,
        enabled: () async => stripOn,
        // A "stripped" copy: one byte shorter.
        prepare: (f) async => PreparedSource(
          sizeBytes: f.sizeBytes - 1,
          read: (s, e) => Stream.value(List.filled(e - s, 9)),
        ),
      ),
    );
    final scopes = ShareScopeStore(sessions: sessions);
    guard = AllowListGuard(
      scopeOf: scopes.scopeOf,
      source: () => files,
      paths: fakeGuard(
        existing: {
          _root,
          for (final f in files.files) ...[f.folderPath, f.path],
        },
      ),
      grants: service,
    );
    // A guarded read and write of a file id, like N7's content and trash.
    Response ok(Request r) =>
        Response.ok(guardedTargetsOf(r).single.canonicalPath);
    handler = buildSharePipeline(
      served: [LocalAddress(InternetAddress('192.168.1.23'), 24, 'wlan0')],
      authenticate: authenticate(sessions),
      routes: [
        ...inboxRoutes(() => service),
        ServerRoute(
          'GET',
          '/v1/files/<id>/content',
          guard.guarded(
            ok,
            write: false,
            extract: (i) async => [FileIdTarget(routeParam(i.request, 'id'))],
          ),
        ),
        ServerRoute(
          'POST',
          '/v1/files/<id>/rename',
          guard.guarded(
            ok,
            write: true,
            extract: (i) async => [FileIdTarget(routeParam(i.request, 'id'))],
          ),
        ),
      ],
    );
    client = sessions.issue(
      clientFingerprint: _fpR,
      clientDeviceId: 'd',
      clientName: 'Laptop',
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
    IssuedSession? as,
  }) async => await handler(
    Request(
      method,
      Uri.parse('https://192.168.1.23:4433$path'),
      headers: {
        'authorization': 'Bearer ${(as ?? client).token}',
        if (json != null) 'content-type': 'application/json',
      },
      body: json == null ? null : jsonEncode(json),
      context: {'shelf.io.connection_info': FakeConnectionInfo('192.168.1.40')},
    ),
  );

  Future<InboxDto> inbox({IssuedSession? as}) async {
    final r = await call('GET', ApiRoutes.inbox, as: as);
    expect(r.statusCode, 200);
    return InboxDto.fromJson(
      jsonDecode(await r.readAsString()) as Map<String, Object?>,
    );
  }

  String content(String id) => '/v1/files/${Uri.encodeComponent(id)}/content';

  test(
    'offer → the inbox lists it (to that client only); token bumps',
    () async {
      final before = service.inboxTokenFor(_fpR);
      final o = await service.offerToClient(_fpR, 'Laptop', picked);
      expect(service.inboxTokenFor(_fpR), isNot(before));
      expect(service.inboxTokenFor(_fpOther), '0');
      final mine = await inbox();
      expect(mine.offers.single.id, o.id);
      expect(mine.offers.single.senderName, 'Tablet');
      expect(
        [for (final f in mine.offers.single.files) (f.name, f.size, f.id)],
        [
          ('a.jpg', 3, 'path:$_root/DCIM/a.jpg'),
          ('b.pdf', 2, 'path:$_root/Docs/b.pdf'),
        ],
      );
      expect((await inbox(as: other)).offers, isEmpty);
      // Not accepted yet: nothing readable.
      expect(
        (await call('GET', content('path:$_root/DCIM/a.jpg'))).statusCode,
        403,
      );
    },
  );

  test(
    'accept grants reads of exactly the offered files, never writes',
    () async {
      final o = await service.offerToClient(_fpR, 'Laptop', picked);
      final steal = await call(
        'POST',
        ApiRoutes.inboxAccept(o.id),
        json: const {},
        as: other,
      );
      expect(steal.statusCode, 404);
      final r = await call('POST', ApiRoutes.inboxAccept(o.id), json: const {});
      expect(r.statusCode, 204);
      expect((await inbox()).offers, isEmpty);
      final read = await call('GET', content('path:$_root/DCIM/a.jpg'));
      expect(read.statusCode, 200);
      expect(await read.readAsString(), '$_root/DCIM/a.jpg');
      // Another file, another client, a write.
      expect(
        (await call('GET', content('path:$_root/DCIM/secret.jpg'))).statusCode,
        403,
      );
      expect(
        (await call(
          'GET',
          content('path:$_root/DCIM/a.jpg'),
          as: other,
        )).statusCode,
        403,
      );
      expect(
        (await call(
          'POST',
          '/v1/files/${Uri.encodeComponent('path:$_root/DCIM/a.jpg')}/rename',
          json: const {},
        )).statusCode,
        403,
      );
      // Finished: the grant ends.
      final f = await call(
        'POST',
        ApiRoutes.inboxFinished(o.id),
        json: const InboxFinishedDto(done: [0, 1]).toJson(),
      );
      expect(f.statusCode, 204);
      expect(
        (await call('GET', content('path:$_root/DCIM/a.jpg'))).statusCode,
        403,
      );
      final row = await ShareOffersDao(db).byId(o.id);
      expect(row?.status, OfferStatus.done);
    },
  );

  test('decline, expiry and the sender taking it back end the offer', () async {
    final a = await service.offerToClient(_fpR, 'Laptop', picked);
    final d = await call('POST', ApiRoutes.inboxDecline(a.id), json: const {});
    expect(d.statusCode, 204);
    expect((await ShareOffersDao(db).byId(a.id))?.status, OfferStatus.declined);

    final b = await service.offerToClient(_fpR, 'Laptop', picked);
    now = now.add(const Duration(minutes: 3));
    expect((await inbox()).offers, isEmpty);
    expect(
      (await call(
        'POST',
        ApiRoutes.inboxAccept(b.id),
        json: const {},
      )).statusCode,
      404,
    );

    final c = await service.offerToClient(_fpR, 'Laptop', picked);
    await call('POST', ApiRoutes.inboxAccept(c.id), json: const {});
    await service.stopByReceiver(c.id);
    expect(
      (await call('GET', content('path:$_root/DCIM/a.jpg'))).statusCode,
      403,
    );
  });

  test(
    'X2 on: photos are offered as staged copies; they go at the end',
    () async {
      stripOn = true;
      final o = await service.offerToClient(_fpR, 'Laptop', picked);
      final listed = (await inbox()).offers.single.files;
      final staged = listed.first;
      expect(staged.size, 2); // the prepared size
      expect(staged.id, startsWith('path:'));
      expect(staged.id, contains('offer-${o.id}'));
      // The pdf isn't a photo: offered as it is.
      expect(listed.last.id, 'path:$_root/Docs/b.pdf');
      final dir = Directory('${staging.path}/offer-${o.id}');
      expect(dir.existsSync(), isTrue);
      await service.stopByReceiver(o.id);
      expect(dir.existsSync(), isFalse);
    },
  );
}
