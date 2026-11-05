import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/platform/host_platform.dart';
import 'package:kfm/core/platform/windows/index_roots.dart';
import 'package:kfm/core/platform/windows/shell_icons.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'file_type_icon.g.dart';

/// Which file icons the desktop lists draw (TASK-E3, `desktop.iconStyle`).
enum DesktopIconStyle {
  /// Windows' own shell icons and type names.
  windows,

  /// KFM's Material icons.
  kfm;

  static DesktopIconStyle parse(String value) =>
      value == kfm.name ? kfm : windows;
}

/// The chosen icon style; KFM icons wherever the shell has none (not
/// Windows, tests).
@Riverpod(keepAlive: true)
Stream<DesktopIconStyle> desktopIconStyle(Ref ref) => ref
    .watch(settingsRepositoryProvider)
    .watch(AppSettings.desktopIconStyle)
    .map(DesktopIconStyle.parse);

/// The shell icon cache, null without the Windows shell.
@Riverpod(keepAlive: true)
ShellIconCache? shellIconCache(Ref ref) {
  if (!isWindowsHost) return null;
  return ShellIconCache(channelIconFetch(ref.watch(windowsChannelProvider)));
}

/// Known folders (lower-case paths) that get their own shell icon
/// (Downloads' arrow, Pictures' image…).
@Riverpod(keepAlive: true)
Future<Set<String>> shellSpecialFolders(Ref ref) async {
  if (!isWindowsHost) return const {};
  try {
    final known = await ref.watch(windowsChannelProvider).knownFolders();
    return {for (final p in known.values) p.toLowerCase()};
  } on Object {
    return const {};
  }
}

/// Explorer's type name for [ext] (`.jpg` → "JPEG image", `folder` → "File
/// folder"); null when there's no shell or it knows none. Cached for the
/// run.
@Riverpod(keepAlive: true)
Future<String?> shellTypeName(Ref ref, String ext) async {
  if (!isWindowsHost || ext.isEmpty) return null;
  try {
    final names = await ref.watch(windowsChannelProvider).fileTypeNames([ext]);
    return names[ext];
  } on Object {
    return null;
  }
}

/// True when the lists draw shell icons now.
bool useShellIcons(WidgetRef ref) =>
    ref.watch(shellIconCacheProvider) != null &&
    (ref.watch(desktopIconStyleProvider).value ?? DesktopIconStyle.windows) ==
        DesktopIconStyle.windows;

enum _IconTarget { file, folder, drive }

/// A file, folder or drive icon: Windows' shell icon when the icon style
/// is `windows`, else (and while loading, or when Windows has none) KFM's
/// Material icon (TASK-E3).
class FileTypeIcon extends ConsumerWidget {
  /// [file]'s icon (by extension; `.exe`/`.lnk` by path).
  const new file(
    FileRef this.file, {
    this.size = 16,
    this.color,
    this.style,
    super.key,
  }) : path = null,
       _target = _IconTarget.file,
       fallback = null;

  /// A file by path only (no [FileRef]: Trash, transfers).
  const new path(
    String this.path, {
    this.size = 16,
    this.color,
    this.fallback,
    this.style,
    super.key,
  }) : file = null,
       _target = _IconTarget.file;

  const new folder(
    String this.path, {
    this.size = 16,
    this.color,
    this.fallback,
    this.style,
    super.key,
  }) : file = null,
       _target = _IconTarget.folder;

  /// A drive root (`C:`).
  const new drive(
    String this.path, {
    this.size = 16,
    this.color,
    this.fallback,
    this.style,
    super.key,
  }) : file = null,
       _target = _IconTarget.drive;

  final FileRef? file;
  final String? path;
  final double size;
  final Color? color;

  /// The KFM icon to show instead (defaults per kind).
  final IconData? fallback;

  /// Draws this style instead of the setting's (the first-run previews).
  final DesktopIconStyle? style;
  final _IconTarget _target;

  IconData get _kfmIcon {
    if (fallback case final f?) return f;
    return switch (_target) {
      _IconTarget.folder => Icons.folder,
      _IconTarget.drive => Icons.storage,
      _IconTarget.file => kfmFileIcon(file?.kind, file?.name ?? path ?? ''),
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kfm = Icon(
      _kfmIcon,
      size: size,
      color:
          color ??
          (_target == _IconTarget.file
              ? Theme.of(context).colorScheme.onSurfaceVariant
              : Theme.of(context).colorScheme.primary),
    );
    final cache = ref.watch(shellIconCacheProvider);
    final shell = switch (style) {
      final s? => s == DesktopIconStyle.windows,
      null => useShellIcons(ref),
    };
    if (!shell || cache == null) return kfm;
    final px = shellIconPx(size, MediaQuery.devicePixelRatioOf(context));
    final key = switch (_target) {
      _IconTarget.file => ShellIconKey.file(file?.path ?? path ?? '', px),
      _IconTarget.folder => ShellIconKey.folder(
        path ?? '',
        px,
        special: ref.watch(shellSpecialFoldersProvider).value ?? const {},
      ),
      _IconTarget.drive => ShellIconKey.drive(path ?? '', px),
    };
    if (cache.hasFailed(key)) return kfm;
    return SizedBox.square(
      dimension: size,
      child: Image(
        image: ShellIconImage(key, cache),
        width: size,
        height: size,
        gaplessPlayback: true,
        frameBuilder: (context, child, frame, sync) =>
            frame == null && !sync ? kfm : child,
        errorBuilder: (context, error, stack) => kfm,
      ),
    );
  }
}

/// KFM's Material icon for a file of [kind] named [name].
IconData kfmFileIcon(FileKind? kind, String name) {
  switch (kind) {
    case FileKind.image:
      return Icons.image_outlined;
    case FileKind.video:
      return Icons.movie_outlined;
    case FileKind.audio:
      return Icons.audiotrack_outlined;
    case _:
  }
  final dot = name.lastIndexOf('.');
  final ext = dot < 0 ? '' : name.substring(dot + 1).toLowerCase();
  return switch (ext) {
    'pdf' => Icons.picture_as_pdf_outlined,
    'zip' || 'rar' || '7z' || 'tar' || 'gz' => Icons.folder_zip_outlined,
    'txt' || 'md' || 'log' || 'csv' || 'json' => Icons.description_outlined,
    'doc' || 'docx' || 'odt' || 'rtf' => Icons.article_outlined,
    'apk' || 'exe' || 'msi' => Icons.apps_outlined,
    _ => Icons.insert_drive_file_outlined,
  };
}
