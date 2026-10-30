import 'package:flutter/material.dart';
import 'package:kfm/app/theme/app_tokens.dart';
import 'package:kfm/core/files/file_kind_resolver.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/thumbs/thumbnail.dart';
import 'package:kfm/core/utils/format.dart';

/// Grid tile (TASK-B1): the thumbnail; non-media files show their name and
/// an extension badge over the type icon.
class FileGridTile extends StatelessWidget {
  const new({
    required this.file,
    required this.onTap,
    this.showSize = false,
    this.highlightBig = false,
    super.key,
  });

  final FileRef file;

  /// Null = a tap does nothing (B6 Edit mode on an unselected file).
  final VoidCallback? onTap;

  /// A size label (Settings → Browse, or sorted by size).
  final bool showSize;

  /// Files of [bigFileBytes]+ get a colored size label, even when
  /// [showSize] is off.
  final bool highlightBig;

  /// Same value as `kBigFileBytes` (Settings → Browse).
  static const int bigFileBytes = 100 * 1024 * 1024;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final spacing = context.tokens.spacing;
    final ext = extensionOf(file.name).toUpperCase();
    final big = highlightBig && file.sizeBytes >= bigFileBytes;
    return Semantics(
      button: true,
      label: file.name,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Thumbnail(file: file),
            if (showSize || big)
              PositionedDirectional(
                start: spacing / 2,
                // Non-media tiles show their name at the bottom.
                bottom: file.isMedia ? spacing / 2 : null,
                top: file.isMedia ? null : spacing / 2,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: big ? scheme.error : Colors.black54,
                    borderRadius: BorderRadius.circular(spacing / 2),
                  ),
                  child: Padding(
                    padding: EdgeInsetsDirectional.symmetric(
                      horizontal: spacing / 2,
                    ),
                    child: Text(
                      formatBytes(
                        file.sizeBytes,
                        locale: Localizations.localeOf(context).toLanguageTag(),
                      ),
                      style: text.labelSmall?.copyWith(
                        color: big ? scheme.onError : Colors.white,
                        fontWeight: big ? FontWeight.bold : null,
                      ),
                    ),
                  ),
                ),
              ),
            if (file.kind == FileKind.video)
              PositionedDirectional(
                end: spacing / 2,
                bottom: spacing / 2,
                child: const Icon(
                  Icons.play_circle_outline,
                  color: Colors.white,
                  shadows: [Shadow(blurRadius: 4)],
                ),
              ),
            if (!file.isMedia) ...[
              if (ext.isNotEmpty)
                PositionedDirectional(
                  top: spacing / 2,
                  end: spacing / 2,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: scheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(spacing / 2),
                    ),
                    child: Padding(
                      padding: EdgeInsetsDirectional.symmetric(
                        horizontal: spacing / 2,
                      ),
                      child: Text(
                        ext,
                        style: text.labelSmall?.copyWith(
                          color: scheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                  ),
                ),
              PositionedDirectional(
                start: spacing / 2,
                end: spacing / 2,
                bottom: spacing / 2,
                child: Text(
                  file.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: text.labelSmall,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// List row for non-media views (documents, audio, archives…).
class FileListRow extends StatelessWidget {
  const new({
    required this.file,
    required this.onTap,
    this.highlightBig = false,
    super.key,
  });

  final FileRef file;

  /// Null = a tap does nothing (B6 Edit mode on an unselected file).
  final VoidCallback? onTap;

  /// Big files' size in the error color.
  final bool highlightBig;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    return ListTile(
      onTap: onTap,
      leading: SizedBox.square(
        dimension: 48,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(context.tokens.spacing / 2),
          child: Thumbnail(file: file),
        ),
      ),
      title: Text(file.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        [
          formatBytes(file.sizeBytes, locale: locale),
          formatDate(file.sortDate, locale: locale),
        ].join(' · '),
        style: highlightBig && file.sizeBytes >= FileGridTile.bigFileBytes
            ? TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.bold,
              )
            : null,
      ),
    );
  }
}
