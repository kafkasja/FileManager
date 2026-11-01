import 'package:flutter/material.dart';
import 'package:kfm/app/theme/app_tokens.dart';
import 'package:kfm/core/files/file_kind_resolver.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/thumbs/thumbnail.dart';
import 'package:kfm/core/utils/format.dart';
import 'package:kfm/core/utils/text_ranges.dart';

/// Grid tile (TASK-B1): the thumbnail; non-media files show their name and
/// an extension badge over the type icon.
class FileGridTile extends StatelessWidget {
  const new({
    required this.file,
    required this.onTap,
    this.showSize = false,
    this.highlightBig = false,
    this.menu,
    this.highlight = const [],
    super.key,
  });

  final FileRef file;

  /// Null = a tap does nothing (B6 Edit mode on an unselected file).
  final VoidCallback? onTap;

  /// B8: name words to highlight (search matches).
  final List<String> highlight;

  /// B4's ⋮ at the bottom-end (Normal mode only).
  final Widget? menu;

  /// A size label (Settings → Browse, or sorted by size).
  final bool showSize;

  /// Files of [bigFileBytes]+ get a colored size label, even when
  /// [showSize] is off.
  final bool highlightBig;

  /// Same value as `kBigFileBytes` (Settings → Browse).
  static const int bigFileBytes = 100 * 1024 * 1024;

  /// What the ⋮ takes at the bottom-end: its 2 px inset, the 8 px tap-target
  /// margin, the 32 px button and a 4 px gap. The name stays clear of it.
  static const double menuExtent = 46;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final spacing = context.tokens.spacing;
    final ext = extensionOf(file.name).toUpperCase();
    final big = highlightBig && file.sizeBytes >= bigFileBytes;
    // The ⋮ sits outside the excluded semantics so TalkBack can reach it.
    return Stack(
      fit: StackFit.expand,
      children: [
        Semantics(
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
                            locale: Localizations.localeOf(context)
                                .toLanguageTag(),
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
                    // Next to the ⋮ when there is one.
                    end: menu == null ? spacing / 2 : spacing / 2 + 36,
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
                    // Never under the ⋮ (H7).
                    end: menu == null ? spacing / 2 : menuExtent,
                    bottom: spacing / 2,
                    child: HighlightedName(
                      name: file.name,
                      words: highlight,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      style: text.labelSmall,
                      breakLongWords: true,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (menu case final menu?)
          PositionedDirectional(end: 2, bottom: 2, child: menu),
      ],
    );
  }
}

/// List row for non-media views (documents, audio, archives…).
class FileListRow extends StatelessWidget {
  const new({
    required this.file,
    required this.onTap,
    this.highlightBig = false,
    this.menu,
    this.highlight = const [],
    super.key,
  });

  final FileRef file;

  /// Null = a tap does nothing (B6 Edit mode on an unselected file).
  final VoidCallback? onTap;

  /// B8: name words to highlight (search matches).
  final List<String> highlight;

  /// B4's ⋮ as the trailing widget (Normal mode only).
  final Widget? menu;

  /// Big files' size in the error color.
  final bool highlightBig;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    return ListTile(
      onTap: onTap,
      trailing: menu,
      leading: SizedBox.square(
        dimension: 48,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(context.tokens.spacing / 2),
          child: Thumbnail(file: file),
        ),
      ),
      title: HighlightedName(name: file.name, words: highlight),
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

/// A file name with the parts matching [words] in bold, primary color (B8).
class HighlightedName extends StatelessWidget {
  const new({
    required this.name,
    this.words = const [],
    this.maxLines = 1,
    this.textAlign = TextAlign.start,
    this.style,
    this.breakLongWords = false,
    super.key,
  });

  final String name;
  final List<String> words;
  final int maxLines;
  final TextAlign textAlign;
  final TextStyle? style;

  /// Lets the name wrap inside long unbroken runs (hashes, base64 names):
  /// display only, the semantics label stays the plain name.
  final bool breakLongWords;

  @override
  Widget build(BuildContext context) {
    final ranges = highlightRanges(name, words);
    final shown = breakLongWords ? withBreakOpportunities : _asIs;
    if (ranges.isEmpty) {
      return Text(
        shown(name),
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        textAlign: textAlign,
        style: style,
      );
    }
    final strong = TextStyle(
      fontWeight: FontWeight.bold,
      color: Theme.of(context).colorScheme.primary,
    );
    final spans = <TextSpan>[];
    var at = 0;
    for (final (start, end) in ranges) {
      if (start > at) {
        spans.add(TextSpan(text: shown(name.substring(at, start))));
      }
      spans.add(
        TextSpan(text: shown(name.substring(start, end)), style: strong),
      );
      at = end;
    }
    if (at < name.length) {
      spans.add(TextSpan(text: shown(name.substring(at))));
    }
    return Text.rich(
      TextSpan(children: spans),
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      textAlign: textAlign,
      style: style,
    );
  }
}

String _asIs(String s) => s;

/// [s] with a zero-width space after every [every] characters of each
/// unbroken run longer than [longerThan] (runs end at a space or `-`, where
/// lines break anyway), so a hash or base64 name can wrap mid-word instead
/// of ending after a few characters (H7). Ordinary names stay as they are.
@visibleForTesting
String withBreakOpportunities(String s, {int every = 8, int longerThan = 12}) =>
    s.splitMapJoin(
      RegExp('[^ -]+'),
      onMatch: (m) {
        final run = m[0]!;
        if (run.length <= longerThan) return run;
        final out = StringBuffer();
        for (var i = 0; i < run.length; i += every) {
          if (i > 0) out.write('​');
          out.write(
            run.substring(i, i + every > run.length ? run.length : i + every),
          );
        }
        return out.toString();
      },
    );
