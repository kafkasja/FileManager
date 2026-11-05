import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/safe_nav.dart';
import 'package:kfm/app/theme/app_tokens.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/core/files/android/files_channel.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/index/index_providers.dart';
import 'package:kfm/core/utils/random_id.dart';
import 'package:kfm/features/browse/ui/widgets/file_actions_menu.dart';
import 'package:kfm/features/privacy/data/privacy_providers.dart';
import 'package:kfm/features/privacy/domain/location_stripper.dart';
import 'package:kfm/features/selection/ui/selection_actions.dart';
import 'package:kfm/l10n/generated/app_localizations.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'share_flow.g.dart';

/// Opens the system share sheet for items `{contentUri?, path?, mime?}`;
/// false when no app can receive them.
typedef ShareSheet = Future<bool> Function(List<Map<String, String?>> items);

/// Android `ACTION_SEND(_MULTIPLE)` (tests override it).
@Riverpod(keepAlive: true)
ShareSheet shareSheet(Ref ref) =>
    (items) async =>
        Platform.isAndroid && await FilesChannel().shareFiles(items);

/// ⋮ menu → Share (TASK-X2).
final FileMenuItem shareFileMenuItem = FileMenuItem(
  id: FileMenuIds.share,
  order: 18,
  label: (c) => c.l10n.privacyShareAction,
  icon: Icons.share_outlined,
  isAvailable: (f) => f.origin != FileOrigin.remote,
  onSelected: (context, ref, f) => shareFiles(context, ref, [f]),
);

/// Selection bar → More → Share (TASK-X2).
final SelectionAction shareSelectionAction = SelectionAction(
  id: 'x2.share',
  order: 8,
  label: (c) => c.l10n.privacyShareAction,
  icon: Icons.share_outlined,
  run: (context, ref, ids) async {
    final files = await ref.read(mediaIndexDaoProvider).byIds(ids);
    if (!context.mounted) return;
    await shareFiles(context, ref, files);
  },
);

/// Share… (TASK-X2): with photos or videos among [files], a sheet first
/// with "Remove location" (preset from Settings → Privacy). On, each photo
/// and video is shared as a copy without location (`<cache>/privacy/`,
/// deleted at the next app start: the receiving app may read it late); a
/// file whose location can't be removed isn't shared, and a dialog names
/// it and says why. Other files are shared as they are.
Future<void> shareFiles(
  BuildContext context,
  WidgetRef ref,
  List<FileRef> files,
) async {
  final local = [
    for (final f in files)
      if (f.origin != FileOrigin.remote) f,
  ];
  if (local.isEmpty) return;
  final media = local.where(LocationStripper.appliesTo).toList();
  var strip = false;
  if (media.isNotEmpty) {
    final preset = await ref
        .read(settingsRepositoryProvider)
        .read(AppSettings.privacyStripLocation);
    if (!context.mounted) return;
    final choice = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _ShareSheet(count: local.length, removeLocation: preset),
    );
    if (choice == null || !context.mounted) return;
    strip = choice;
  }
  final stripped = <String, StrippedFile>{};
  final failed = <(FileRef, LocationStripFailure)>[];
  if (strip) {
    final stripper = ref.read(locationStripperProvider);
    final sendId = 'share-${randomHexId()}';
    final progress = ValueNotifier<int>(0);
    final dialog = DialogHandle<void>();
    unawaited(
      dialog.show(
        context,
        barrierDismissible: false,
        builder: (_) =>
            _ProgressDialog(progress: progress, total: media.length),
      ),
    );
    try {
      for (final f in media) {
        try {
          stripped[f.id] = await stripper.stripToTemp(f, sendId: sendId);
        } on LocationStripException catch (e) {
          failed.add((f, e.reason));
        }
        progress.value++;
      }
    } finally {
      // The notifier isn't disposed: the dialog may still be closing.
      dialog.close();
    }
    if (!context.mounted) return;
  }
  final items = <Map<String, String?>>[
    for (final f in local)
      if (stripped[f.id] case final copy?)
        {'path': copy.path, 'mime': f.mimeType}
      else if (!strip || !LocationStripper.appliesTo(f))
        _original(f),
  ];
  if (failed.isNotEmpty) {
    await _showFailures(context, failed);
    if (!context.mounted) return;
  }
  if (items.isEmpty) return;
  final shown = await ref.read(shareSheetProvider)(items);
  if (!shown && context.mounted) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(context.l10n.privacyShareNoApp)));
  }
}

/// A file shared as it is: MediaStore items by URI, others by path.
Map<String, String?> _original(FileRef f) => f.uri.startsWith('content://')
    ? {'contentUri': f.uri, 'mime': f.mimeType}
    : {'path': f.path, 'mime': f.mimeType};

/// The reason of a failed strip, for a dialog line.
String locationStripFailureText(
  AppLocalizations l10n,
  LocationStripFailure reason,
) => switch (reason) {
  LocationStripFailure.stillHasLocation => l10n.privacyFailStillHasLocation,
  LocationStripFailure.unsupportedFormat => l10n.privacyFailUnsupported,
  LocationStripFailure.readFailed => l10n.privacyFailReadFailed,
};

Future<void> _showFailures(
  BuildContext context,
  List<(FileRef, LocationStripFailure)> failed,
) => showDialog<void>(
  context: context,
  builder: (context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.privacyCouldNotStrip(failed.length)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final (f, reason) in failed)
              Padding(
                padding: EdgeInsetsDirectional.only(
                  bottom: context.tokens.spacing / 2,
                ),
                child: Text(
                  l10n.privacyFailedLine(
                    f.name,
                    locationStripFailureText(l10n, reason),
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.ok),
        ),
      ],
    );
  },
);

class _ShareSheet extends StatefulWidget {
  const new({required this.count, required this.removeLocation});

  final int count;
  final bool removeLocation;

  @override
  State<_ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends State<_ShareSheet> {
  late bool _remove = widget.removeLocation;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final gap = context.tokens.spacing;
    // Scrolls on short screens; the buttons wrap when they don't fit.
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsetsDirectional.fromSTEB(0, 0, 0, gap),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              title: Text(
                l10n.privacyShareTitle(widget.count),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            SwitchListTile(
              key: const ValueKey('share-remove-location'),
              secondary: const Icon(Icons.location_off_outlined),
              title: Text(l10n.privacyShareRemoveLocation),
              subtitle: Text(l10n.privacyShareRemoveLocationHelp),
              value: _remove,
              onChanged: (v) => setState(() => _remove = v),
            ),
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(gap, gap, gap, 0),
              child: OverflowBar(
                alignment: MainAxisAlignment.end,
                overflowAlignment: OverflowBarAlignment.end,
                spacing: gap,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l10n.cancel),
                  ),
                  FilledButton.icon(
                    key: const ValueKey('share-confirm'),
                    icon: const Icon(Icons.share_outlined),
                    onPressed: () => Navigator.pop(context, _remove),
                    label: Text(l10n.privacyShareAction),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressDialog extends StatelessWidget {
  const new({required this.progress, required this.total});

  final ValueNotifier<int> progress;
  final int total;

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    child: AlertDialog(
      content: Row(
        children: [
          const CircularProgressIndicator(),
          SizedBox(width: context.tokens.spacing * 2),
          Expanded(
            child: ValueListenableBuilder<int>(
              valueListenable: progress,
              builder: (context, done, _) =>
                  Text(context.l10n.privacyRemovingLocation(done, total)),
            ),
          ),
        ],
      ),
    ),
  );
}
