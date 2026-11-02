import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/features/connect/data/pinned_client.dart';
import 'package:kfm/features/connect/domain/protocol.dart';

Map<String, Object?> _rt(Map<String, Object?> json) =>
    jsonDecode(jsonEncode(json)) as Map<String, Object?>;

void main() {
  const hello = ClientHelloDto(
    pairAttemptId: 'p',
    clientDeviceId: 'd',
    clientName: 'PC',
    clientPlatform: 'windows',
    clientCertPem: 'pem',
  );

  test('error codes: complete list with wire names and statuses', () {
    expect(
      {for (final c in ApiErrorCode.values) c.wire: c.status},
      {
        'unauthorized': 401,
        'forbidden': 403,
        'forbidden_path': 403,
        'not_found': 404,
        'conflict': 409,
        'busy': 409,
        'pairing_failed': 401,
        'secret_used': 401,
        'expired': 401,
        'too_many_attempts': 429,
        'declined': 403,
        'timed_out': 403,
        'cancelled': 410,
        'unsupported_version': 400,
        'insufficient_storage': 507,
        'too_large': 413,
        'pending_folder_unavailable': 409,
        'invalid_name': 400,
        'verification_failed': 409,
        'internal': 500,
      },
    );
    expect(ApiErrorCode.fromWire('forbidden_path'), ApiErrorCode.forbiddenPath);
    expect(ApiErrorCode.fromWire('new_in_v2'), isNull);
  });

  test('unauthenticated routes; first-contact routes are a subset', () {
    expect(kUnauthenticatedRoutes, {
      'GET /v1/info',
      'POST /v1/pair/nonce',
      'POST /v1/pair/code/start',
      'POST /v1/pair',
      'POST /v1/pair/known',
      'POST /v1/pair/cancel',
    });
    expect(
      kUnauthenticatedRoutes.containsAll(PinnedClient.firstContactRoutes),
      isTrue,
    );
  });

  test('ServerInfoDto round-trips and ignores unknown fields', () {
    const info = ServerInfoDto(
      deviceId: 'id',
      name: 'Phone',
      platform: 'android',
      fingerprint: 'fp',
      protocolVersion: 1,
    );
    final json = _rt(info.toJson())..['extra'] = true;
    final back = ServerInfoDto.fromJson(json);
    expect(back.toJson(), info.toJson());
    expect(
      () => ServerInfoDto.fromJson(const {'deviceId': 'x'}),
      throwsFormatException,
    );
  });

  test('pairing DTOs round-trip', () {
    const qr = PairRequestDto(
      hello: hello,
      credential: QrCredential(secret: 's', nonce: 'n', sig: 'g'),
    );
    expect(PairRequestDto.fromJson(_rt(qr.toJson())).toJson(), qr.toJson());
    expect(qr.toJson()['credential'], containsPair('type', 'qr'));

    const code = PairRequestDto(
      hello: hello,
      credential: CodeCredential(attemptId: 'a', confirmA: 'c', sig: 'g'),
    );
    final back = PairRequestDto.fromJson(_rt(code.toJson()));
    expect(back.credential, isA<CodeCredential>());
    expect(back.toJson(), code.toJson());

    const known = KnownPairRequestDto(hello: hello, nonce: 'n', sig: 'g');
    expect(
      KnownPairRequestDto.fromJson(_rt(known.toJson())).toJson(),
      known.toJson(),
    );

    const accepted = PairAcceptedDto(
      token: 't',
      serverDeviceId: 'id',
      roots: [RootDto(id: 'r', label: 'Camera', readOnly: true)],
    );
    expect(
      PairAcceptedDto.fromJson(_rt(accepted.toJson())).toJson(),
      accepted.toJson(),
    );

    expect(
      () => PairCredential.fromJson({'type': 'magic'}),
      throwsFormatException,
    );
  });

  test('ApiErrorDto never throws on a malformed body', () {
    final e = ApiErrorDto.fromJson(const {'code': 3});
    expect(e.code, 'internal');
    expect(e.message, '');
  });
}
