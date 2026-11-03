import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/theme/app_tokens.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/core/platform/permissions/storage_access_provider.dart';
import 'package:kfm/features/cloud/data/cloud_destinations_repository.dart';
import 'package:kfm/features/cloud/data/cloud_providers.dart';
import 'package:kfm/features/cloud/domain/cloud_destination.dart';
import 'package:kfm/features/cloud/ui/cloud_labels.dart';

final FutureProvider<bool> _gpsNoteVisible = FutureProvider.autoDispose<bool>((
  ref,
) async {
  final settings = ref.watch(settingsRepositoryProvider);
  if (await settings.read(AppSettings.cloudGpsNoteDismissed)) return false;
  return !await ref.read(permissionServiceProvider).hasMediaLocation();
});

/// Settings → Cloud → Cloud destinations (TASK-X3): add (system folder
/// picker), rename, remove (soft), "Needs reconnecting" from the
/// persisted-permission check, the provider help text and the one-time
/// location note.
class CloudSettingsScreen extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<CloudSettingsScreen> createState() =>
      _CloudSettingsScreenState();
}

class _CloudSettingsScreenState extends ConsumerState<CloudSettingsScreen> {
  bool _busy = false;

  void _snack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _add() async {
    if (_busy) return;
    setState(() => _busy = true);
    final l10n = context.l10n;
    try {
      final repo = ref.read(cloudDestinationsRepositoryProvider);
      final outcome = await repo.addFromPicker();
      switch (outcome) {
        case CloudAddOutcome.added:
          ref.invalidate(cloudDestinationHealthProvider);
          final list = await repo.watchActive().first;
          if (list.isNotEmpty) {
            final newest = list.reduce(
              (a, b) => a.addedAt.isAfter(b.addedAt) ? a : b,
            );
            _snack(l10n.cloudAdded(newest.label));
          }
        case CloudAddOutcome.failed:
          _snack(l10n.cloudAddFailed);
        case CloudAddOutcome.cancelled:
          break;
      }
    } on Object catch (e) {
      _snack(e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _rename(CloudDestination d) async {
    final l10n = context.l10n;
    final controller = TextEditingController(text: d.label);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.cloudRename),
        content: TextField(
          key: const ValueKey('cloud-rename-field'),
          controller: controller,
          autofocus: true,
          maxLength: kCloudLabelMax,
          onSubmitted: (v) => Navigator.pop(context, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            key: const ValueKey('cloud-rename-save'),
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(l10n.cloudRename),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || clampCloudLabel(name).isEmpty) return;
    try {
      await ref.read(cloudDestinationsRepositoryProvider).rename(d.id, name);
    } on Object catch (e) {
      _snack(e.toString());
    }
  }

  Future<void> _remove(CloudDestination d) async {
    final l10n = context.l10n;
    var forget = false;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(l10n.cloudRemoveTitle(d.label)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.cloudRemoveConfirm),
              CheckboxListTile(
                key: const ValueKey('cloud-forget-uploads'),
                contentPadding: EdgeInsetsDirectional.zero,
                value: forget,
                onChanged: (v) => setDialogState(() => forget = v ?? false),
                title: Text(l10n.cloudForgetUploads),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              key: const ValueKey('cloud-remove-confirm'),
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.cloudRemove),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    try {
      // The runner stops a copy running into it and deletes partial
      // documents before the grant is released.
      final runner = ref.read(cloudUploadRunnerProvider);
      if (runner != null) {
        await runner.removeDestination(d.id, forgetUploads: forget);
      } else {
        await ref
            .read(cloudDestinationsRepositoryProvider)
            .remove(d.id, forgetUploads: forget);
      }
    } on Object catch (e) {
      _snack(e.toString());
    }
  }

  Future<void> _allowLocation() async {
    final perms = ref.read(permissionServiceProvider);
    if (!await perms.requestMediaLocation() &&
        await perms.mediaLocationPermanentlyDenied()) {
      await perms.openAppSettings();
    }
    ref.invalidate(_gpsNoteVisible);
  }

  void _dismissGpsNote() {
    ref
        .read(settingsRepositoryProvider)
        .write(AppSettings.cloudGpsNoteDismissed, true)
        .fireAndForget();
    ref.invalidate(_gpsNoteVisible);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final spacing = context.tokens.spacing;
    final list = ref.watch(activeCloudDestinationsProvider).value ?? const [];
    final health =
        ref.watch(cloudDestinationHealthProvider).value ??
        const <int, CloudDestinationHealth>{};
    final gpsNote =
        list.isNotEmpty && (ref.watch(_gpsNoteVisible).value ?? false);
    final canAdd = ref.watch(cloudTreePlatformProvider) != null;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.cloudDestinations)),
      floatingActionButton: canAdd
          ? FloatingActionButton.extended(
              key: const ValueKey('cloud-add'),
              onPressed: _busy ? null : () => unawaited(_add()),
              icon: const Icon(Icons.add),
              label: Text(l10n.cloudAdd),
            )
          : null,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsetsDirectional.only(bottom: spacing * 10),
          children: [
            Padding(
              padding: EdgeInsetsDirectional.all(spacing * 2),
              child: Text(l10n.cloudHowItWorks),
            ),
            if (gpsNote)
              Card(
                key: const ValueKey('cloud-gps-note'),
                margin: EdgeInsetsDirectional.symmetric(
                  horizontal: spacing * 2,
                  vertical: spacing,
                ),
                child: Padding(
                  padding: EdgeInsetsDirectional.all(spacing * 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.cloudGpsNote),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: _dismissGpsNote,
                            child: Text(l10n.dismiss),
                          ),
                          FilledButton(
                            onPressed: () => unawaited(_allowLocation()),
                            child: Text(l10n.cloudGpsAllow),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            if (list.isEmpty)
              Padding(
                padding: EdgeInsetsDirectional.all(spacing * 2),
                child: Text(
                  l10n.cloudEmpty,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            for (final d in list)
              ListTile(
                key: ValueKey('cloud-dest-${d.id}'),
                leading: Icon(cloudProviderIcon(d.provider)),
                title: Text(d.label),
                subtitle:
                    health[d.id] == CloudDestinationHealth.needsReconnecting
                    ? Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Chip(
                          avatar: const Icon(Icons.link_off, size: 18),
                          label: Text(l10n.cloudNeedsReconnecting),
                        ),
                      )
                    : null,
                onTap: health[d.id] == CloudDestinationHealth.needsReconnecting
                    ? () => unawaited(_add())
                    : null,
                trailing: PopupMenuButton<String>(
                  key: ValueKey('cloud-dest-menu-${d.id}'),
                  onSelected: (v) => unawaited(switch (v) {
                    'rename' => _rename(d),
                    'reconnect' => _add(),
                    _ => _remove(d),
                  }),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'rename',
                      child: Text(l10n.cloudRename),
                    ),
                    if (health[d.id] ==
                        CloudDestinationHealth.needsReconnecting)
                      PopupMenuItem(
                        value: 'reconnect',
                        child: Text(l10n.cloudReconnect),
                      ),
                    PopupMenuItem(
                      key: const ValueKey('cloud-menu-remove'),
                      value: 'remove',
                      child: Text(l10n.cloudRemove),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: EdgeInsetsDirectional.all(spacing * 2),
              child: Text(
                l10n.cloudNoFolderPicking,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
