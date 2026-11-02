import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// One forbidden HTTP pattern plus the `lib/`-relative files allowed to use
/// it (TASK-N5: every request to a remote device goes through PinnedClient).
class _Rule {
  const new(
    this.name,
    this.pattern, [
    this.allowed = const {},
    this.allowedForm,
  ]);

  final String name;
  final RegExp pattern;

  /// `lib/`-relative paths (forward slashes) where the pattern is allowed.
  final Set<String> allowed;

  /// When set, an allowed file may only use the pattern in this exact form
  /// (checked per occurrence, starting at the match).
  final RegExp? allowedForm;
}

const _pinnedClient = 'features/connect/data/pinned_client.dart';

/// C3's public AI model download (user taps Download, rule 7). It goes to a
/// public host over normal system-trusted TLS and refuses non-https URLs,
/// so it can't use a device-pinned client; it never talks to a KFM device.
const _aiModelStore = 'features/ai_labels/data/ai_model_store.dart';

/// S5's player pool: remote videos play through the N5 loopback proxy
/// (`http://127.0.0.1:<port>`), which forwards over PinnedClient.
/// X7's opt-in update check: one GET to api.github.com (public host,
/// system-trusted TLS); it never talks to a KFM device.
const _releaseClient = 'features/updates/data/github_release_client.dart';

const _videoPool = 'features/swipe/ui/video_controller_pool.dart';

final List<_Rule> _rules = [
  _Rule('HttpClient(', RegExp(r'\bHttpClient\('), {
    _pinnedClient,
    _aiModelStore,
    _releaseClient,
  }),
  _Rule('HttpClient.new', RegExp(r'\bHttpClient\.new\b'), {
    _pinnedClient,
    _aiModelStore,
    _releaseClient,
  }),
  _Rule('package:http/', RegExp('package:http/')),
  _Rule('NetworkImage(', RegExp(r'\bNetworkImage\(')),
  _Rule('Image.network(', RegExp(r'\bImage\.network\(')),
  _Rule('networkUrl(', RegExp(r'\bnetworkUrl\('), {
    _videoPool,
  }, RegExp(r'networkUrl\(\s*proxy\.urlFor\(')),
  _Rule(
    'badCertificateCallback =',
    RegExp(r'badCertificateCallback\s*=(?!=)'),
    {_pinnedClient},
  ),
];

/// `path: pattern` for every unpinned-HTTP use under [libDir] (a `lib/`-like
/// folder). Skips generated code (`*.g.dart`, `l10n/generated`).
List<String> findUnpinnedHttp(Directory libDir) {
  final root = libDir.absolute.path.replaceAll(r'\', '/');
  final hits = <String>[];
  final files = libDir.listSync(recursive: true).whereType<File>().toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  for (final f in files) {
    final abs = f.absolute.path.replaceAll(r'\', '/');
    if (!abs.endsWith('.dart') || abs.endsWith('.g.dart')) continue;
    final rel = abs.substring(root.length).replaceFirst(RegExp('^/+'), '');
    if (rel.startsWith('l10n/generated/')) continue;
    final text = f.readAsStringSync();
    for (final rule in _rules) {
      for (final m in rule.pattern.allMatches(text)) {
        final form = rule.allowedForm;
        final ok =
            rule.allowed.contains(rel) &&
            (form == null || form.matchAsPrefix(text, m.start) != null);
        if (!ok) hits.add('lib/$rel: ${rule.name}');
      }
    }
  }
  return hits;
}

void main() {
  test('lib/ makes no HTTP request outside PinnedClient', () {
    expect(findUnpinnedHttp(Directory('lib')), isEmpty);
  });

  test('the check catches every pattern and honours the allow-list', () {
    final dir = Directory.systemTemp.createTempSync('kfm_http_check');
    addTearDown(() => dir.deleteSync(recursive: true));
    void put(String rel, String text) => File('${dir.path}/$rel')
      ..createSync(recursive: true)
      ..writeAsStringSync(text);

    // Offenders.
    put('a.dart', 'final c = HttpClient();\n');
    put('b.dart', 'final f = HttpClient.new;\n');
    put('c.dart', "import 'package:http/http.dart' as http;\n");
    put('d.dart', "final i = NetworkImage('https://x');\n");
    put('e.dart', "final w = Image.network('https://x');\n");
    put('f.dart', 'final v = VideoPlayerController.networkUrl(u);\n');
    put('g.dart', 'void f(HttpClient c) { c.badCertificateCallback = t; }\n');
    put(
      _videoPool,
      'final a = VideoPlayerController.networkUrl(proxy.urlFor(file));\n'
      'final b = VideoPlayerController.networkUrl(Uri.parse(raw));\n',
    );
    // Allowed.
    put(
      _pinnedClient,
      'final h = HttpClient(context: SecurityContext())\n'
      '  ..badCertificateCallback = _trust;\n',
    );
    put(_aiModelStore, 'final f = HttpClient.new;\nfinal g = HttpClient();\n');
    put(
      'features/swipe/ui/other.dart',
      'void f(HttpClient Function() make, HttpServer s) {}\n',
    );
    // Skipped (generated).
    put('x.g.dart', 'final c = HttpClient();\n');
    put('l10n/generated/y.dart', 'final c = HttpClient();\n');

    final hits = findUnpinnedHttp(dir);
    expect(hits, [
      'lib/a.dart: HttpClient(',
      'lib/b.dart: HttpClient.new',
      'lib/c.dart: package:http/',
      'lib/d.dart: NetworkImage(',
      'lib/e.dart: Image.network(',
      'lib/f.dart: networkUrl(',
      'lib/$_videoPool: networkUrl(',
      'lib/g.dart: badCertificateCallback =',
    ]);
  });
}
