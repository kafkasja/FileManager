import 'package:kfm/core/files/file_ref.dart';

const _archiveMimes = {
  'application/zip',
  'application/x-zip-compressed',
  'application/vnd.rar',
  'application/x-rar-compressed',
  'application/x-7z-compressed',
  'application/x-tar',
  'application/gzip',
  'application/x-gzip',
  'application/x-bzip2',
  'application/x-xz',
};

const _archiveExtensions = {
  'zip',
  'rar',
  '7z',
  'tar',
  'gz',
  'tgz',
  'bz2',
  'xz',
};

const _documentExtensions = {
  'pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'txt', 'odt', 'ods', //
  'odp', 'rtf', 'csv', 'epub', 'md',
};

const _imageExtensions = {
  'jpg', 'jpeg', 'png', 'gif', 'webp', 'heic', 'heif', 'bmp', 'dng', 'avif', //
};

const _videoExtensions = {
  'mp4', 'mkv', 'mov', 'webm', '3gp', 'avi', 'm4v', 'ts', //
};

const _audioExtensions = {
  'mp3', 'm4a', 'aac', 'wav', 'ogg', 'opus', 'flac', 'amr', 'mid', //
};

/// Lower-case extension without the dot, or '' when there is none.
String extensionOf(String name) {
  final dot = name.lastIndexOf('.');
  if (dot <= 0 || dot == name.length - 1) return '';
  return name.substring(dot + 1).toLowerCase();
}

/// Kind from MIME type first, then from the file extension.
FileKind kindFor(String? mime, String name) {
  final m = mime?.toLowerCase();
  if (m != null) {
    if (m.startsWith('image/')) return FileKind.image;
    if (m.startsWith('video/')) return FileKind.video;
    if (m.startsWith('audio/')) return FileKind.audio;
    if (_archiveMimes.contains(m)) return FileKind.archive;
  }
  final ext = extensionOf(name);
  if (_imageExtensions.contains(ext)) return FileKind.image;
  if (_videoExtensions.contains(ext)) return FileKind.video;
  if (_audioExtensions.contains(ext)) return FileKind.audio;
  if (_archiveExtensions.contains(ext)) return FileKind.archive;
  if (_documentExtensions.contains(ext)) return FileKind.document;
  if (m != null &&
      (m == 'application/pdf' ||
          m.startsWith('text/') ||
          m.contains('officedocument') ||
          m.contains('opendocument') ||
          m == 'application/msword' ||
          m == 'application/epub+zip')) {
    return FileKind.document;
  }
  return FileKind.other;
}
