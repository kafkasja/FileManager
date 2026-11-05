import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/thumbs/thumbnail.dart';
import 'package:kfm/core/utils/format.dart';
import 'package:kfm/desktop/widgets/desktop_metrics.dart';
import 'package:kfm/desktop/widgets/explorer_view.dart';
import 'package:kfm/desktop/widgets/file_type_icon.dart';
import 'package:kfm/l10n/generated/app_localizations.dart';

/// A file tile for the icon layouts: rounded thumbnail (the phone's tile
/// look), name below; a small video badge. E3: files that aren't photos or
/// videos show Windows' big shell icon (with the Windows icon style).
class FileTileBody extends ConsumerWidget {
  const new({required this.file, this.badge, super.key});

  final FileRef file;

  /// Drawn over the thumbnail's top-start corner (e.g. reviewed).
  final Widget? badge;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final shellIcon = !file.isMedia && useShellIcons(ref);
    return Column(
      children: [
        Expanded(
          child: shellIcon
              ? LayoutBuilder(
                  builder: (context, c) => Center(
                    child: FileTypeIcon.file(
                      file,
                      size: (c.biggest.shortestSide * 0.8).clamp(16, 96),
                    ),
                  ),
                )
              : ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Thumbnail(file: file),
                      if (file.kind == FileKind.video)
                        const PositionedDirectional(
                          end: 4,
                          bottom: 4,
                          child: _Badge(icon: Icons.play_arrow),
                        ),
                      if (badge case final b?)
                        PositionedDirectional(start: 4, top: 4, child: b),
                    ],
                  ),
                ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: scaledExtent(context, 32),
          child: Text(
            file.name,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const new({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Colors.black54,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Padding(
      padding: const EdgeInsets.all(2),
      child: Icon(icon, size: 14, color: Colors.white),
    ),
  );
}

/// "JPG file" (Explorer's Type column without the shell).
String fileTypeLabel(AppLocalizations l10n, String name) {
  final dot = name.lastIndexOf('.');
  if (dot <= 0 || dot == name.length - 1) return l10n.desktopTypeUnknown;
  return l10n.desktopTypeFile(name.substring(dot + 1).toUpperCase());
}

/// `.jpg` of [name] (lower case), '' without one.
String fileExtensionOf(String name) {
  final dot = name.lastIndexOf('.');
  if (dot <= 0 || dot == name.length - 1) return '';
  return name.substring(dot).toLowerCase();
}

/// E3: the Type column text: Windows' type name ("JPEG image") when the
/// shell knows one, else [fileTypeLabel].
class FileTypeText extends ConsumerWidget {
  const new(this.name, {this.style, super.key});

  final String name;
  final TextStyle? style;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ext = fileExtensionOf(name);
    final shell = ext.isEmpty
        ? null
        : ref.watch(shellTypeNameProvider(ext)).value;
    return Text(
      shell ?? fileTypeLabel(context.l10n, name),
      style: style,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// Ids of the Details columns (sorting).
abstract final class FileColumns {
  static const name = 'name';
  static const date = 'date';
  static const size = 'size';
  static const type = 'type';
  static const folder = 'folder';
}

/// Name · Date · Size · Type columns for files, mapped through [fileOf]
/// (the item may wrap a file, e.g. Browse's folder-or-file entries).
List<ExplorerColumn<T>> fileColumns<T>(
  BuildContext context, {
  required FileRef? Function(T item) fileOf,
  required Widget Function(BuildContext context, T item) nameCell,
  String? Function(T item)? typeOf,
  bool sortable = true,
  bool folderColumn = false,
}) {
  final l10n = context.l10n;
  final locale = Localizations.localeOf(context).toLanguageTag();
  final small = Theme.of(context).textTheme.bodySmall;
  Widget text(String s) =>
      Text(s, style: small, maxLines: 1, overflow: TextOverflow.ellipsis);
  return [
    ExplorerColumn<T>(
      id: FileColumns.name,
      label: l10n.browseSortName,
      expand: true,
      sortable: sortable,
      cell: nameCell,
    ),
    if (folderColumn)
      ExplorerColumn<T>(
        id: FileColumns.folder,
        label: l10n.desktopColumnFolder,
        width: 220,
        cell: (context, item) => switch (fileOf(item)) {
          final f? => Tooltip(
            message: f.folderPath.replaceAll('/', r'\'),
            child: text(f.folderPath.replaceAll('/', r'\')),
          ),
          null => const SizedBox.shrink(),
        },
      ),
    ExplorerColumn<T>(
      id: FileColumns.date,
      label: l10n.browseSortDate,
      width: 170,
      sortable: sortable,
      cell: (context, item) => switch (fileOf(item)) {
        final f? => text(formatDateAndTime(f.sortDate, locale: locale)),
        null => const SizedBox.shrink(),
      },
    ),
    ExplorerColumn<T>(
      id: FileColumns.type,
      label: l10n.detailsType,
      width: 130,
      cell: (context, item) => switch ((typeOf?.call(item), fileOf(item))) {
        (final String t, _) => text(t),
        (null, final f?) => FileTypeText(f.name, style: small),
        (null, null) => const SizedBox.shrink(),
      },
    ),
    ExplorerColumn<T>(
      id: FileColumns.size,
      label: l10n.detailsSize,
      width: 100,
      alignEnd: true,
      sortable: sortable,
      cell: (context, item) => switch (fileOf(item)) {
        final f? => text(formatBytes(f.sizeBytes, locale: locale)),
        null => const SizedBox.shrink(),
      },
    ),
  ];
}

/// A Details row's name cell: small thumbnail (or [icon]) + name. E3: with
/// the Windows icon style every row shows its 16 px shell icon, like
/// Explorer's Details view ([folderPath] for folders).
class FileNameCell extends ConsumerWidget {
  const new({
    required this.name,
    this.file,
    this.icon,
    this.folderPath,
    super.key,
  });

  final String name;
  final FileRef? file;
  final IconData? icon;

  /// A folder row's path (its shell icon).
  final String? folderPath;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Row(
    children: [
      SizedBox.square(
        dimension: 22,
        child: switch ((file, folderPath)) {
          (final f?, _) when useShellIcons(ref) => Center(
            child: FileTypeIcon.file(f),
          ),
          (final f?, _) => ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Thumbnail(file: f),
          ),
          (null, final p?) when p.length == 2 && p.endsWith(':') => Center(
            child: FileTypeIcon.drive(p, size: useShellIcons(ref) ? 16 : 20),
          ),
          (null, final p?) => Center(
            child: FileTypeIcon.folder(
              p,
              size: useShellIcons(ref) ? 16 : 20,
              fallback: icon,
            ),
          ),
          (null, null) => Icon(
            icon ?? Icons.folder,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
        },
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    ],
  );
}

/// "Oct 23, 2026 14:05" in local time (Explorer's Date column).
String formatDateAndTime(DateTime date, {String? locale}) =>
    DateFormat.yMMMd(locale).add_Hm().format(date.toLocal());
