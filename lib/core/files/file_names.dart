import 'package:kfm/core/files/file_op_exception.dart';

/// Splits "photo.jpg" into ("photo", ".jpg"); dot-files keep their name.
(String, String) splitExtension(String name) {
  final dot = name.lastIndexOf('.');
  if (dot <= 0) return (name, '');
  return (name.substring(0, dot), name.substring(dot));
}

/// [name], or the first free `name (1).ext`, `name (2).ext`… for which
/// [exists] returns false. Never overwrites.
Future<String> uniqueName(
  String name,
  Future<bool> Function(String candidate) exists,
) async {
  if (!await exists(name)) return name;
  final (base, ext) = splitExtension(name);
  for (var i = 1; ; i++) {
    final candidate = '$base ($i)$ext';
    if (!await exists(candidate)) return candidate;
  }
}

/// Throws `invalidName` for names that can't be a single path segment.
void validateFileName(String name) {
  if (name.trim().isEmpty ||
      name == '.' ||
      name == '..' ||
      name.contains('/') ||
      name.contains(r'\') ||
      name.contains('\u0000')) {
    throw FileOpException(FileOpFailure.invalidName, 'invalid name: "$name"');
  }
}

/// Absolute '/'-separated folder of [path], without trailing '/'.
String parentOf(String path) {
  final i = path.lastIndexOf('/');
  return i <= 0 ? '/' : path.substring(0, i);
}

/// Last segment of [path].
String nameOf(String path) => path.substring(path.lastIndexOf('/') + 1);

/// True if any folder segment of [path] below [root] starts with '.'.
bool isInHiddenFolder(String path, {String root = ''}) {
  final rel = path.startsWith(root) ? path.substring(root.length) : path;
  final segments = rel.split('/');
  // The last segment is the file itself.
  for (var i = 0; i < segments.length - 1; i++) {
    if (segments[i].startsWith('.')) return true;
  }
  return false;
}
