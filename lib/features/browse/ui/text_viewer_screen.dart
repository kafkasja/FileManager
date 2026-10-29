import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/theme/app_tokens.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/files/file_source_provider.dart';
import 'package:kfm/features/browse/domain/text_preview.dart';
import 'package:kfm/features/browse/ui/open_file.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'text_viewer_screen.g.dart';

/// Reads the start of [file] (at most `kTextViewerMaxBytes`) and decodes
/// it (in an isolate unless it is small).
@riverpod
Future<TextPreview> textPreview(Ref ref, FileRef file) async {
  final builder = BytesBuilder(copy: false);
  var truncated = false;
  await for (final chunk in ref.watch(fileSourceProvider).openRead(file)) {
    final room = kTextViewerMaxBytes - builder.length;
    if (chunk.length > room) {
      builder.add(chunk.sublist(0, room));
      truncated = true;
      break;
    }
    builder.add(chunk);
  }
  final bytes = builder.takeBytes();
  // Spawning an isolate costs more than decoding a small file.
  if (bytes.length < 64 * 1024) {
    return decodeTextPreview(bytes, truncated: truncated);
  }
  return await Isolate.run(
    () => decodeTextPreview(bytes, truncated: truncated),
  );
}

/// Read-only text viewer (TASK-B1): monospace, selectable, wrapped.
class TextViewerScreen extends StatelessWidget {
  const new({required this.file, super.key});

  static Route<void> route(FileRef file) =>
      MaterialPageRoute(builder: (_) => TextViewerScreen(file: file));

  final FileRef file;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(file.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      actions: [OpenWithButton(file: file)],
    ),
    body: TextViewerBody(file: file),
  );
}

/// The scrollable content, also a page of B7's paged viewer.
class TextViewerBody extends ConsumerWidget {
  const new({required this.file, super.key});

  final FileRef file;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final spacing = context.tokens.spacing;
    final theme = Theme.of(context);
    return switch (ref.watch(textPreviewProvider(file))) {
      AsyncData(value: TextPreviewBinary()) => Center(
        child: Padding(
          padding: EdgeInsets.all(spacing * 3),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.textViewerBinary, textAlign: TextAlign.center),
              SizedBox(height: spacing * 2),
              FilledButton.icon(
                onPressed: () => openWithOrExplain(context, ref, file),
                icon: const Icon(Icons.open_in_new),
                label: Text(l10n.openWith),
              ),
            ],
          ),
        ),
      ),
      AsyncData(value: final TextPreviewText t) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (t.truncated) _Notice(text: l10n.textViewerTruncated),
          if (t.latin1) _Notice(text: l10n.textViewerLatin1),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(spacing * 2),
              child: SelectableText(
                t.text,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
        ],
      ),
      AsyncError() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.textViewerError),
            SizedBox(height: spacing),
            OutlinedButton(
              onPressed: () => ref.invalidate(textPreviewProvider(file)),
              child: Text(l10n.retry),
            ),
          ],
        ),
      ),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}

class _Notice extends StatelessWidget {
  const new({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: scheme.secondaryContainer,
      child: Padding(
        padding: EdgeInsets.all(context.tokens.spacing),
        child: Text(text, style: TextStyle(color: scheme.onSecondaryContainer)),
      ),
    );
  }
}
