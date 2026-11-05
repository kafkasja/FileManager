import 'package:kfm/core/files/file_kind_resolver.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/utils/format.dart';
import 'package:kfm/l10n/generated/app_localizations.dart';

/// What a screen reader says a file is (TASK-E2 §7): Photo, Video, PDF
/// document, "ZIP file"…
String fileKindSpoken(AppLocalizations l10n, FileRef file) {
  final ext = extensionOf(file.name).toUpperCase();
  return switch (file.kind) {
    FileKind.image => l10n.fileKindPhoto,
    FileKind.video => l10n.fileKindVideo,
    FileKind.audio => l10n.a11yKindAudio,
    FileKind.document when ext.isNotEmpty => l10n.a11yKindDocumentExt(ext),
    FileKind.document => l10n.a11yKindDocument,
    FileKind.archive => l10n.a11yKindArchive,
    FileKind.other when ext.isNotEmpty => l10n.a11yKindFileExt(ext),
    FileKind.other => l10n.a11yKindFile,
  };
}

/// "cat.mp4, Video, 312 MB, 4 Nov 2026": name, kind, size and date
/// ([date] or the file's sort date) in KFM's language. Built from the
/// [FileRef] alone (no DB reads), lazily per visible tile.
String fileSemanticsLabel(
  AppLocalizations l10n,
  FileRef file, {
  DateTime? date,
}) => l10n.a11yFileLabel(
  file.name,
  fileKindSpoken(l10n, file),
  formatBytes(file.sizeBytes, locale: l10n.localeName),
  formatDate(date ?? file.sortDate, locale: l10n.localeName),
);
