import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:kfm/core/files/file_op_exception.dart';
import 'package:kfm/core/files/saf/saf_channel.dart';
import 'package:kfm/core/files/saf/saf_file_source.dart';

class _Node {
  new dir() : bytes = null;
  new file(List<int> this.bytes);

  List<int>? bytes;
  int modifiedMs = 1000;
  bool get isDir => bytes == null;
}

/// An in-memory externalstorage provider for one tree (TASK-U2 tests):
/// document ids are `<uuid>:<relative path>`, like the real one.
class FakeSafPlatform implements SafPlatform {
  new({this.uuid = 'ABCD-1234'}) {
    _nodes[''] = _Node.dir();
  }

  final String uuid;
  final Map<String, _Node> _nodes = {};

  /// Every mutating call (for assertions).
  final List<String> calls = [];

  /// `move` answers null (a provider that can't move).
  bool refuseMove = false;

  /// `move` throws (a provider error).
  bool failMove = false;

  String get treeUri =>
      'content://com.android.externalstorage.documents/tree/$uuid%3A';
  String get root => '/storage/$uuid';
  SafTree get tree => SafTree(root: root, treeUri: treeUri, rootDoc: '$uuid:');

  String _rel(String doc) {
    if (!doc.startsWith('$uuid:')) {
      throw FileOpException(FileOpFailure.notFound, 'doc $doc');
    }
    return doc.substring(uuid.length + 1);
  }

  String _doc(String rel) => '$uuid:$rel';
  static String _join(String parent, String name) =>
      parent.isEmpty ? name : '$parent/$name';
  static String _name(String rel) => rel.substring(rel.lastIndexOf('/') + 1);
  static String _parent(String rel) {
    final i = rel.lastIndexOf('/');
    return i < 0 ? '' : rel.substring(0, i);
  }

  SafDoc _row(String rel) {
    final n = _nodes[rel]!;
    return SafDoc(
      id: _doc(rel),
      name: _name(rel),
      mime: n.isDir ? SafDoc.dirMime : null,
      sizeBytes: n.bytes?.length ?? 0,
      modifiedMs: n.modifiedMs,
    );
  }

  _Node _node(String doc) =>
      _nodes[_rel(doc)] ??
      (throw FileOpException(FileOpFailure.notFound, 'doc $doc'));

  // ---- test helpers ----

  /// Adds a file at [path] (under [root]) with its folders.
  String addFile(String path, List<int> bytes, {int modifiedMs = 1000}) {
    final rel = path.substring(root.length + 1);
    _mkdirs(_parent(rel));
    _nodes[rel] = _Node.file(bytes)..modifiedMs = modifiedMs;
    return _doc(rel);
  }

  void addFolder(String path) =>
      _mkdirs(path == root ? '' : path.substring(root.length + 1));

  void _mkdirs(String rel) {
    if (rel.isEmpty || _nodes.containsKey(rel)) return;
    _mkdirs(_parent(rel));
    _nodes[rel] = _Node.dir();
  }

  void removeDoc(String doc) => _removeTree(_rel(doc));

  bool existsPath(String path) =>
      _nodes.containsKey(path == root ? '' : path.substring(root.length + 1));

  List<int>? bytesAt(String path) =>
      _nodes[path.substring(root.length + 1)]?.bytes;

  /// Corrupts the next imported file (verification tests).
  bool corruptNextImport = false;

  void _removeTree(String rel) =>
      _nodes.removeWhere((k, _) => k == rel || k.startsWith('$rel/'));

  void _relocate(String from, String to) {
    final moved = {
      for (final e in _nodes.entries)
        if (e.key == from || e.key.startsWith('$from/')) e.key: e.value,
    };
    moved.keys.forEach(_nodes.remove);
    for (final e in moved.entries) {
      _nodes['$to${e.key.substring(from.length)}'] = e.value;
    }
  }

  // ---- SafPlatform ----

  @override
  Future<List<SafDoc>> list(String tree, String doc) async {
    final rel = _rel(doc);
    if (_nodes[rel]?.isDir != true) {
      throw FileOpException(FileOpFailure.notFound, 'no folder $doc');
    }
    return [
      for (final k in _nodes.keys)
        if (k.isNotEmpty && _parent(k) == rel) _row(k),
    ];
  }

  @override
  Future<SafDoc?> stat(String tree, String doc) async {
    final rel = doc.startsWith('$uuid:') ? _rel(doc) : null;
    return rel != null && _nodes.containsKey(rel) ? _row(rel) : null;
  }

  @override
  Future<Uint8List> read(String tree, String doc, int start, int length) async {
    final b = _node(doc).bytes!;
    if (start >= b.length) return Uint8List(0);
    final end = start + length > b.length ? b.length : start + length;
    return Uint8List.fromList(b.sublist(start, end));
  }

  @override
  Future<({int sizeBytes, String sha256})> copyOut(
    String tree,
    String doc,
    String path,
  ) async {
    final b = _node(doc).bytes!;
    await File(path).writeAsBytes(b);
    return (sizeBytes: b.length, sha256: crypto.sha256.convert(b).toString());
  }

  @override
  Future<SafDoc> importFile(
    String tree,
    String parent,
    String name,
    String? mime,
    String path,
  ) async {
    calls.add('importFile $name');
    final rel = _join(_rel(parent), name);
    if (_nodes.containsKey(rel)) {
      throw FileOpException(FileOpFailure.targetExists, rel);
    }
    var bytes = await File(path).readAsBytes();
    if (corruptNextImport) {
      corruptNextImport = false;
      bytes = Uint8List.fromList([...bytes, 0]);
    }
    _nodes[rel] = _Node.file(bytes);
    return _row(rel);
  }

  @override
  Future<SafDoc> createDir(String tree, String parent, String name) async {
    calls.add('createDir $name');
    final rel = _join(_rel(parent), name);
    _nodes[rel] = _Node.dir();
    return _row(rel);
  }

  @override
  Future<SafDoc> rename(String tree, String doc, String name) async {
    calls.add('rename $name');
    final rel = _rel(doc);
    _node(doc);
    final to = _join(_parent(rel), name);
    if (to != rel && _nodes.containsKey(to)) {
      throw FileOpException(FileOpFailure.targetExists, to);
    }
    _relocate(rel, to);
    return _row(to);
  }

  @override
  Future<SafDoc?> move(String tree, String doc, String from, String to) async {
    calls.add('move ${_name(_rel(doc))}');
    if (refuseMove) return null;
    if (failMove) throw const FileOpException(FileOpFailure.ioError, 'move');
    final rel = _rel(doc);
    _node(doc);
    final target = _join(_rel(to), _name(rel));
    if (_nodes.containsKey(target)) {
      throw FileOpException(FileOpFailure.targetExists, target);
    }
    _relocate(rel, target);
    return _row(target);
  }

  @override
  Future<void> delete(String tree, String doc) async {
    calls.add('delete ${_name(_rel(doc))}');
    _removeTree(_rel(doc));
  }

  @override
  Future<String> sha256(String tree, String doc) async =>
      sha256Hex(_node(doc).bytes!);

  static String sha256Hex(List<int> b) => crypto.sha256.convert(b).toString();

  @override
  Future<Uint8List?> thumbnail(String tree, String doc, int size) async => null;

  @override
  Future<void> writeText(
    String tree,
    String parent,
    String name,
    String text,
  ) async {
    _nodes[_join(_rel(parent), name)] = _Node.file(text.codeUnits);
  }

  @override
  Future<String?> readText(String tree, String parent, String name) async {
    final b = _nodes[_join(_rel(parent), name)]?.bytes;
    return b == null ? null : String.fromCharCodes(b);
  }
}
