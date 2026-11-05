import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/core/files/file_kind_resolver.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/thumbs/thumbnail.dart';
import 'package:kfm/core/utils/format.dart';
import 'package:kfm/desktop/widgets/file_explorer_parts.dart';
import 'package:kfm/desktop/widgets/file_type_icon.dart';
import 'package:kfm/features/details/ui/file_details_sheet.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'desktop_side_pane.g.dart';

/// The right pane's mode (TASK-E3, Explorer's Preview / Details pane).
enum DesktopSidePane { none, preview, details }

/// Alt+P / Alt+Shift+P (View ▾); remembered (`desktop.sidePane`). Off by
/// default (rule 5).
@Riverpod(keepAlive: true)
class DesktopSidePaneMode extends _$DesktopSidePaneMode {
  @override
  DesktopSidePane build() {
    unawaited(_restore());
    return DesktopSidePane.none;
  }

  var _touched = false;

  Future<void> _restore() async {
    try {
      final v = await ref
          .read(settingsRepositoryProvider)
          .read(AppSettings.desktopSidePane);
      if (!ref.mounted || _touched) return;
      state = DesktopSidePane.values.asNameMap()[v] ?? DesktopSidePane.none;
    } on Object {
      // Off stays.
    }
  }

  /// Shows [pane], or hides it when it is the one shown.
  void toggle(DesktopSidePane pane) {
    _touched = true;
    state = state == pane ? DesktopSidePane.none : pane;
    ref
        .read(settingsRepositoryProvider)
        .write(AppSettings.desktopSidePane, state.name)
        .fireAndForget();
  }
}

/// A right pane (Preview or Details) is shown.
@Riverpod(keepAlive: true)
bool desktopDetailsPane(Ref ref) =>
    ref.watch(desktopSidePaneModeProvider) != DesktopSidePane.none;

/// The first 64 KB of a text file, for the Preview pane.
@riverpod
Future<String> desktopTextPreview(Ref ref, String path) async {
  final file = File(path);
  final bytes = <int>[];
  await file.openRead(0, 64 * 1024).forEach(bytes.addAll);
  return utf8.decode(bytes, allowMalformed: true);
}

/// Preview: the photo/video frame, a text file's start, else a big icon
/// with the name, type and size.
class DesktopPreviewPane extends ConsumerWidget {
  const new({required this.file, super.key});

  final FileRef? file;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final f = file;
    if (f == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsetsDirectional.all(24),
          child: Text(
            l10n.desktopPreviewNothing,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }
    final locale = Localizations.localeOf(context).toLanguageTag();
    final Widget body;
    if (f.isMedia) {
      body = ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: AspectRatio(aspectRatio: 1, child: Thumbnail(file: f)),
      );
    } else if (isTextFile(f)) {
      body = switch (ref.watch(desktopTextPreviewProvider(f.path))) {
        AsyncData(:final value) => Container(
          key: const ValueKey('preview-text'),
          constraints: const BoxConstraints(maxHeight: 480),
          padding: const EdgeInsetsDirectional.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(6),
          ),
          child: SingleChildScrollView(
            child: SelectableText(
              value,
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'Consolas',
              ),
            ),
          ),
        ),
        AsyncError() => Center(child: FileTypeIcon.file(f, size: 96)),
        _ => const Center(child: CircularProgressIndicator()),
      };
    } else {
      body = Center(child: FileTypeIcon.file(f, size: 96));
    }
    return ListView(
      key: const ValueKey('desktop-preview-pane'),
      padding: const EdgeInsetsDirectional.all(16),
      children: [
        body,
        const SizedBox(height: 12),
        Text(f.name, style: theme.textTheme.titleSmall),
        const SizedBox(height: 4),
        FileTypeText(f.name, style: theme.textTheme.bodySmall),
        Text(
          formatBytes(f.sizeBytes, locale: locale),
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}

/// The pane on the right of the shell: Preview or Details of [file].
class DesktopSidePaneView extends ConsumerWidget {
  const new({required this.file, super.key});

  final FileRef? file;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(desktopSidePaneModeProvider);
    final f = file;
    if (mode == DesktopSidePane.preview) {
      return DesktopPreviewPane(key: ValueKey('preview-${f?.id}'), file: f);
    }
    if (f == null) {
      final theme = Theme.of(context);
      return Center(
        child: Padding(
          padding: const EdgeInsetsDirectional.all(24),
          child: Text(
            context.l10n.desktopDetailsNothing,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }
    return FileDetailsView(key: ValueKey(f.id), file: f);
  }
}
