import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/features/updates/data/github_release_client.dart';
import 'package:kfm/features/updates/domain/app_version.dart';
import 'package:kfm/features/updates/domain/release_info.dart';
import 'package:kfm/features/updates/domain/update_status.dart';

Map<String, Object?> releaseJson({
  String tag = 'v0.2.0',
  String url = 'https://github.com/kafkasja/FileManager/releases/tag/v0.2.0',
}) => {
  'tag_name': tag,
  'name': 'KFM 0.2.0',
  'body': 'Fixes',
  'html_url': url,
  'published_at': '2026-11-01T10:00:00Z',
};

void main() {
  group('AppVersion', () {
    test('parses and compares', () {
      expect(
        AppVersion.tryParse('v0.10.0')! > AppVersion.tryParse('0.9.9')!,
        isTrue,
      );
      expect(AppVersion.tryParse('0.2.0-beta'), const AppVersion(0, 2, 0));
      expect(AppVersion.tryParse('1.2.3+4'), const AppVersion(1, 2, 3));
      expect(AppVersion.tryParse('garbage'), isNull);
      expect(AppVersion.tryParse('1.2'), isNull);
      expect(const AppVersion(1, 0, 0) > const AppVersion(1, 0, 0), isFalse);
    });
  });

  group('ReleaseInfo', () {
    test('round-trips; refuses foreign pages', () {
      final r = parseRelease(jsonEncode(releaseJson()));
      final back = ReleaseInfo.tryDecode(r.encode())!;
      expect(back.version, r.version);
      expect(back.pageUrl, r.pageUrl);
      expect(ReleaseInfo.tryDecode(''), isNull);
      expect(ReleaseInfo.tryDecode('{nope'), isNull);
      expect(isReleasePage(Uri.parse('https://evil.example/releases/')), false);
      expect(
        isReleasePage(
          Uri.parse('https://github.com/kafkasja/FileManager2/releases/x'),
        ),
        isFalse,
      );
    });
  });

  group('GitHubReleaseClient (loopback server)', () {
    late HttpServer server;
    late int status;
    late String body;
    final headers = <HttpHeaders>[];
    final paths = <String>[];

    setUp(() async {
      headers.clear();
      paths.clear();
      status = 200;
      body = jsonEncode(releaseJson());
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0)
        ..listen((req) async {
          headers.add(req.headers);
          paths.add(req.uri.toString());
          req.response
            ..statusCode = status
            ..write(body);
          await req.response.close();
        });
    });

    tearDown(() => server.close(force: true));

    GitHubReleaseClient client() => GitHubReleaseClient(
      endpoint: Uri.parse(
        'http://127.0.0.1:${server.port}/repos/kafkasja/FileManager/releases/latest',
      ),
    );

    Future<ReleaseCheckFailure?> failure() async {
      try {
        await client().latest();
        return null;
      } on ReleaseCheckException catch (e) {
        return e.failure;
      }
    }

    test('200: the release; only the planned headers, no query', () async {
      final r = await client().latest();
      expect(r!.version, const AppVersion(0, 2, 0));
      expect(r.notes, 'Fixes');
      expect(paths.single, '/repos/kafkasja/FileManager/releases/latest');
      final h = headers.single;
      expect(h.value(HttpHeaders.userAgentHeader), 'KFM');
      expect(h.value(HttpHeaders.acceptHeader), 'application/vnd.github+json');
      expect(h.value('X-GitHub-Api-Version'), '2022-11-28');
      expect(h.value(HttpHeaders.cookieHeader), isNull);
      expect(h.value(HttpHeaders.authorizationHeader), isNull);
    });

    test('404: no release', () async {
      status = 404;
      expect(await client().latest(), isNull);
    });

    test('403 / 429: busy', () async {
      status = 403;
      expect(await failure(), ReleaseCheckFailure.busy);
      status = 429;
      expect(await failure(), ReleaseCheckFailure.busy);
    });

    test('bad JSON, foreign html_url, odd tag', () async {
      body = '{oops';
      expect(await failure(), ReleaseCheckFailure.badResponse);
      body = jsonEncode(releaseJson(url: 'https://evil.example/x'));
      expect(await failure(), ReleaseCheckFailure.badResponse);
      body = jsonEncode(releaseJson(tag: 'nightly'));
      expect(await failure(), ReleaseCheckFailure.unparsableTag);
    });

    test('server gone: offline', () async {
      final c = client();
      await server.close(force: true);
      try {
        await c.latest();
        fail('expected an error');
      } on ReleaseCheckException catch (e) {
        expect(e.failure, ReleaseCheckFailure.offline);
      }
    });
  });
}
