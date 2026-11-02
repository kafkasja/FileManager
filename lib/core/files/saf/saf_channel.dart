import 'package:flutter/services.dart';
import 'package:kfm/core/files/file_op_exception.dart';
import 'package:meta/meta.dart';

/// One document row from `SafChannel.kt` (TASK-U2).
@immutable
class SafDoc {
  const new({
    required this.id,
    required this.name,
    required this.mime,
    required this.sizeBytes,
    required this.modifiedMs,
    this.flags = 0,
  });

  factory fromRow(Map<Object?, Object?> r) => SafDoc(
    id: r['id']! as String,
    name: r['name'] as String? ?? '',
    mime: r['mime'] as String?,
    sizeBytes: (r['size'] as num?)?.toInt() ?? 0,
    modifiedMs: (r['modified'] as num?)?.toInt() ?? 0,
    flags: (r['flags'] as num?)?.toInt() ?? 0,
  );

  static const dirMime = 'vnd.android.document/directory';

  final String id;
  final String name;
  final String? mime;
  final int sizeBytes;
  final int modifiedMs;
  final int flags;

  bool get isDir => mime == dirMime;
}

/// Files inside persisted SAF trees (Android: [SafChannel]). Every call
/// takes the tree URI and a document id. Failures throw
/// [FileOpException].
abstract interface class SafPlatform {
  Future<List<SafDoc>> list(String tree, String doc);

  /// Null when the document is gone.
  Future<SafDoc?> stat(String tree, String doc);

  /// Up to [length] bytes from [start] (fewer at the end).
  Future<Uint8List> read(String tree, String doc, int start, int length);

  /// Copies the document into the local file [path].
  Future<({int sizeBytes, String sha256})> copyOut(
    String tree,
    String doc,
    String path,
  );

  /// Creates [name] in [parent] from the local file [path]; a partial
  /// document is deleted on failure.
  Future<SafDoc> importFile(
    String tree,
    String parent,
    String name,
    String? mime,
    String path,
  );
  Future<SafDoc> createDir(String tree, String parent, String name);
  Future<SafDoc> rename(String tree, String doc, String name);

  /// Same-tree move; null when the provider can't.
  Future<SafDoc?> move(String tree, String doc, String from, String to);

  /// Gone already counts as done.
  Future<void> delete(String tree, String doc);
  Future<String> sha256(String tree, String doc);
  Future<Uint8List?> thumbnail(String tree, String doc, int size);
  Future<void> writeText(String tree, String parent, String name, String text);
  Future<String?> readText(String tree, String parent, String name);
}

/// Typed wrapper around `com.kaf.kfm/saf`.
class SafChannel implements SafPlatform {
  new({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(name);

  static const name = 'com.kaf.kfm/saf';

  final MethodChannel _channel;

  Future<T?> _call<T>(String method, Map<String, Object?> args) async {
    try {
      return await _channel.invokeMethod<T>(method, args);
    } on PlatformException catch (e) {
      throw FileOpException(switch (e.code) {
        'NOT_FOUND' => FileOpFailure.notFound,
        'PERMISSION' => FileOpFailure.permissionDenied,
        'NO_SPACE' => FileOpFailure.noSpace,
        'UNSUPPORTED' => FileOpFailure.unsupported,
        _ => FileOpFailure.ioError,
      }, 'saf $method: ${e.message}');
    }
  }

  SafDoc _doc(Map<Object?, Object?>? row, String what) => row == null
      ? throw FileOpException(FileOpFailure.ioError, 'saf $what: no row')
      : SafDoc.fromRow(row);

  @override
  Future<List<SafDoc>> list(String tree, String doc) async {
    final rows = await _call<List<Object?>>('list', {'tree': tree, 'doc': doc});
    return [
      for (final r in rows ?? const <Object?>[])
        if (r is Map<Object?, Object?>) SafDoc.fromRow(r),
    ];
  }

  @override
  Future<SafDoc?> stat(String tree, String doc) async {
    final row = await _call<Map<Object?, Object?>>('stat', {
      'tree': tree,
      'doc': doc,
    });
    return row == null ? null : SafDoc.fromRow(row);
  }

  @override
  Future<Uint8List> read(
    String tree,
    String doc,
    int start,
    int length,
  ) async =>
      await _call<Uint8List>('read', {
        'tree': tree,
        'doc': doc,
        'start': start,
        'length': length,
      }) ??
      Uint8List(0);

  @override
  Future<({int sizeBytes, String sha256})> copyOut(
    String tree,
    String doc,
    String path,
  ) async {
    final r = await _call<Map<Object?, Object?>>('copyOut', {
      'tree': tree,
      'doc': doc,
      'path': path,
    });
    return (
      sizeBytes: (r?['size'] as num?)?.toInt() ?? 0,
      sha256: r?['sha256'] as String? ?? '',
    );
  }

  @override
  Future<SafDoc> importFile(
    String tree,
    String parent,
    String name,
    String? mime,
    String path,
  ) async => _doc(
    await _call<Map<Object?, Object?>>('importFile', {
      'tree': tree,
      'parent': parent,
      'name': name,
      'mime': mime,
      'path': path,
    }),
    'importFile',
  );

  @override
  Future<SafDoc> createDir(String tree, String parent, String name) async =>
      _doc(
        await _call<Map<Object?, Object?>>('createDir', {
          'tree': tree,
          'parent': parent,
          'name': name,
        }),
        'createDir',
      );

  @override
  Future<SafDoc> rename(String tree, String doc, String name) async => _doc(
    await _call<Map<Object?, Object?>>('rename', {
      'tree': tree,
      'doc': doc,
      'name': name,
    }),
    'rename',
  );

  @override
  Future<SafDoc?> move(String tree, String doc, String from, String to) async {
    final row = await _call<Map<Object?, Object?>>('move', {
      'tree': tree,
      'doc': doc,
      'from': from,
      'to': to,
    });
    return row == null ? null : SafDoc.fromRow(row);
  }

  @override
  Future<void> delete(String tree, String doc) async {
    final ok = await _call<bool>('delete', {'tree': tree, 'doc': doc});
    if (ok != true) {
      throw FileOpException(FileOpFailure.ioError, 'saf delete refused: $doc');
    }
  }

  @override
  Future<String> sha256(String tree, String doc) async =>
      await _call<String>('sha256', {'tree': tree, 'doc': doc}) ??
      (throw const FileOpException(FileOpFailure.ioError, 'saf sha256'));

  @override
  Future<Uint8List?> thumbnail(String tree, String doc, int size) =>
      _call<Uint8List>('thumbnail', {'tree': tree, 'doc': doc, 'size': size});

  @override
  Future<void> writeText(
    String tree,
    String parent,
    String name,
    String text,
  ) => _call<bool>('writeText', {
    'tree': tree,
    'parent': parent,
    'name': name,
    'text': text,
  });

  @override
  Future<String?> readText(String tree, String parent, String name) =>
      _call<String>('readText', {'tree': tree, 'parent': parent, 'name': name});
}
