import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:kfm/features/updates/domain/app_version.dart';
import 'package:kfm/features/updates/domain/release_info.dart';
import 'package:kfm/features/updates/domain/update_status.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'github_release_client.g.dart';

/// Where the latest release comes from (TASK-X7). Fakes in tests.
abstract interface class ReleaseClient {
  /// Null when there is no release (404). Throws [ReleaseCheckException].
  Future<ReleaseInfo?> latest();
}

/// The one request X7 makes: GitHub's "latest release" of KFM's repo, with
/// no auth, cookies, app version or device data.
class GitHubReleaseClient implements ReleaseClient {
  new({
    HttpClient Function()? httpClient,
    Uri? endpoint,
    this.timeout = const Duration(seconds: 10),
  }) : _httpClient = httpClient ?? HttpClient.new,
       _endpoint = endpoint ?? defaultEndpoint;

  static final Uri defaultEndpoint = Uri.parse(
    'https://api.github.com/repos/kafkasja/FileManager/releases/latest',
  );

  /// Release notes are short; anything bigger isn't a release response.
  static const int maxBodyBytes = 1 << 20;

  final HttpClient Function() _httpClient;
  final Uri _endpoint;
  final Duration timeout;

  @override
  Future<ReleaseInfo?> latest() async {
    final client = _httpClient()
      ..connectionTimeout = timeout
      ..userAgent = 'KFM';
    try {
      final req = await client.getUrl(_endpoint).timeout(timeout);
      req.headers
        ..set(HttpHeaders.acceptHeader, 'application/vnd.github+json')
        ..set('X-GitHub-Api-Version', '2022-11-28')
        ..set(HttpHeaders.userAgentHeader, 'KFM');
      final res = await req.close().timeout(timeout);
      final bytes = await _readCapped(res).timeout(timeout);
      switch (res.statusCode) {
        case HttpStatus.ok:
          return parseRelease(utf8.decode(bytes, allowMalformed: true));
        case HttpStatus.notFound:
          return null;
        case HttpStatus.forbidden || HttpStatus.tooManyRequests:
          throw ReleaseCheckException(
            ReleaseCheckFailure.busy,
            'HTTP ${res.statusCode}',
          );
        default:
          throw ReleaseCheckException(
            ReleaseCheckFailure.badResponse,
            'HTTP ${res.statusCode}',
          );
      }
    } on SocketException catch (e) {
      throw ReleaseCheckException(ReleaseCheckFailure.offline, '$e');
    } on TimeoutException catch (e) {
      throw ReleaseCheckException(ReleaseCheckFailure.offline, '$e');
    } on TlsException catch (e) {
      throw ReleaseCheckException(ReleaseCheckFailure.offline, '$e');
    } on HttpException catch (e) {
      throw ReleaseCheckException(ReleaseCheckFailure.offline, '$e');
    } finally {
      client.close(force: true);
    }
  }

  static Future<List<int>> _readCapped(HttpClientResponse res) async {
    final out = BytesBuilder(copy: false);
    await for (final chunk in res) {
      out.add(chunk);
      if (out.length > maxBodyBytes) {
        throw const ReleaseCheckException(
          ReleaseCheckFailure.badResponse,
          'response too large',
        );
      }
    }
    return out.takeBytes();
  }
}

/// Parses GitHub's release JSON (`tag_name`, `name`, `body`, `html_url`,
/// `published_at`). The page must be in KFM's own repository.
ReleaseInfo parseRelease(String body) {
  final Object? j;
  try {
    j = jsonDecode(body);
  } on FormatException catch (e) {
    throw ReleaseCheckException(ReleaseCheckFailure.badResponse, '$e');
  }
  if (j is! Map<String, Object?>) {
    throw const ReleaseCheckException(
      ReleaseCheckFailure.badResponse,
      'not an object',
    );
  }
  final tag = j['tag_name'];
  final url = Uri.tryParse(
    j['html_url'] is String ? j['html_url']! as String : '',
  );
  if (url == null || !isReleasePage(url)) {
    throw const ReleaseCheckException(
      ReleaseCheckFailure.badResponse,
      'release page outside the repository',
    );
  }
  final version = tag is String ? AppVersion.tryParse(tag) : null;
  if (version == null) {
    throw ReleaseCheckException(ReleaseCheckFailure.unparsableTag, 'tag $tag');
  }
  final published = j['published_at'];
  return ReleaseInfo(
    version: version,
    title: j['name'] is String ? j['name']! as String : '',
    notes: j['body'] is String ? j['body']! as String : '',
    pageUrl: url,
    publishedAt:
        (published is String ? DateTime.tryParse(published) : null) ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
  );
}

@Riverpod(keepAlive: true)
ReleaseClient releaseClient(Ref ref) => GitHubReleaseClient();
