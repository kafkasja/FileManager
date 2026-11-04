// Windows-only (TASK-PL3): KFM's file clipboard against the real runner and
// a second process that uses the clipboard the way Explorer does (.NET's
// FileDropList + "Preferred DropEffect", read and written from PowerShell).
// Run with
//   flutter test integration_test/windows_clipboard_test.dart -d windows
// It overwrites whatever is on the clipboard and empties it at the end.
@TestOn('windows')
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kfm/core/platform/windows/windows_clipboard.dart';

/// Runs [script] in Windows PowerShell (STA, which the clipboard needs).
Future<String> _ps(String script) async {
  const prelude =
      '[Console]::OutputEncoding = [Text.Encoding]::UTF8; '
      'Add-Type -AssemblyName System.Windows.Forms; ';
  final r = await Process.run('powershell.exe', [
    '-NoProfile',
    '-NonInteractive',
    '-STA',
    '-Command',
    '$prelude$script',
  ], stdoutEncoding: utf8);
  if (r.exitCode != 0) {
    fail('PowerShell failed (${r.exitCode}): ${r.stderr}');
  }
  return (r.stdout as String).trim();
}

String _psQuote(String s) => "'${s.replaceAll("'", "''")}'";

String _norm(String p) => p.replaceAll('/', r'\').toLowerCase();

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;
  late List<String> files;
  final clip = WindowsFileClipboard();

  setUpAll(() async {
    dir = await Directory.systemTemp.createTemp('kfm_clip_');
    files = [
      for (final name in ['a.txt', 'b ü.txt', 'c [1].txt'])
        (File('${dir.path}\\$name')..writeAsStringSync(name)).path,
    ];
  });

  tearDownAll(() async {
    await clip.clear();
    await dir.delete(recursive: true);
  });

  /// What another program sees: the file list and the drop effect
  /// (1 = copy, 2 = move, 5 = copy|link; empty when absent).
  Future<(List<String>, String)> readOutside() async {
    final out = await _ps(
      r'$d = [Windows.Forms.Clipboard]::GetDataObject(); '
      r'$f = [Windows.Forms.Clipboard]::GetFileDropList(); '
      r'$e = $d.GetData("Preferred DropEffect"); '
      r'$v = if ($e) { $b = New-Object byte[] 4; [void]$e.Read($b, 0, 4); '
      r'[BitConverter]::ToInt32($b, 0) } else { "" }; '
      r'"EFFECT=$v"; foreach ($p in $f) { "FILE=$p" }',
    );
    final lines = out.split(RegExp(r'\r?\n'));
    return (
      [
        for (final l in lines)
          if (l.startsWith('FILE=')) l.substring(5),
      ],
      lines.firstWhere((l) => l.startsWith('EFFECT=')).substring(7),
    );
  }

  /// Puts [paths] on the clipboard like Explorer's Copy / Cut.
  Future<void> writeOutside(List<String> paths, {required bool cut}) => _ps(
    r'$c = New-Object Collections.Specialized.StringCollection; '
    '${[for (final p in paths) '[void]\$c.Add(${_psQuote(p)}); '].join()}'
    r'$d = New-Object Windows.Forms.DataObject; $d.SetFileDropList($c); '
    r'$d.SetData("Preferred DropEffect", '
    '(New-Object IO.MemoryStream(,[byte[]](${cut ? 2 : 5},0,0,0)))); '
    r'[Windows.Forms.Clipboard]::SetDataObject($d, $true)',
  );

  test('KFM Copy is seen by another program as a file copy', () async {
    final seq = await clip.write([
      for (final f in files) f.replaceAll(r'\', '/'),
    ], cut: false);
    expect(seq, isNotNull);
    final (paths, effect) = await readOutside();
    expect(paths.map(_norm), files.map(_norm));
    expect(effect, '5');
  });

  test('KFM Cut is seen as a move', () async {
    await clip.write([files.first.replaceAll(r'\', '/')], cut: true);
    final (paths, effect) = await readOutside();
    expect(paths.map(_norm), [_norm(files.first)]);
    expect(effect, '2');
  });

  test("another program's Copy reads back in KFM", () async {
    final before = (await clip.read())?.sequence ?? 0;
    await writeOutside(files, cut: false);
    final got = await clip.read();
    expect(got, isNotNull);
    expect(got!.paths.map(_norm), files.map(_norm));
    expect(got.cut, isFalse);
    expect(got.sequence, isNot(before));
  });

  test("another program's Cut reads back as cut", () async {
    await writeOutside(files.sublist(1), cut: true);
    final got = await clip.read();
    expect(got!.paths.map(_norm), files.sublist(1).map(_norm));
    expect(got.cut, isTrue);
  });

  test('text on the clipboard is no files', () async {
    await _ps("[Windows.Forms.Clipboard]::SetText('hello')");
    final got = await clip.read();
    expect(got?.paths ?? const <String>[], isEmpty);
  });

  test('clear empties it for other programs too', () async {
    await clip.write([files.first.replaceAll(r'\', '/')], cut: true);
    await clip.clear();
    final (paths, _) = await readOutside();
    expect(paths, isEmpty);
    expect((await clip.read())?.paths ?? const <String>[], isEmpty);
  });
}
