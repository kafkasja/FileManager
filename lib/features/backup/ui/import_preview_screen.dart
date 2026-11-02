import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/features/backup/data/backup_providers.dart';
import 'package:kfm/features/backup/domain/backup_codec.dart';
import 'package:kfm/features/backup/domain/import_plan.dart';

/// What an import would change (TASK-X6). Pops `true` once applied;
/// Cancel or back writes nothing.
class ImportPreviewScreen extends ConsumerStatefulWidget {
  const new({required this.data, super.key});

  final BackupData data;

  @override
  ConsumerState<ImportPreviewScreen> createState() =>
      _ImportPreviewScreenState();
}

class _ImportPreviewScreenState extends ConsumerState<ImportPreviewScreen> {
  static const _listLimit = 200;

  late final Future<ImportPlan> _plan = _build();
  bool _applySettings = true;
  bool _applying = false;
  Object? _applyError;

  Future<ImportPlan> _build() async {
    final suffix = context.l10n.backupImportedSuffix;
    // Match against a fresh index (files added since the last scan).
    await ref.read(backupIndexRefreshProvider)();
    return await ref
        .read(backupServiceProvider)
        .plan(widget.data, importedSuffix: suffix);
  }

  Future<void> _apply(ImportPlan plan) async {
    setState(() {
      _applying = true;
      _applyError = null;
    });
    try {
      await ref
          .read(backupServiceProvider)
          .apply(plan, applySettings: _applySettings);
      if (mounted) Navigator.of(context).pop(true);
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          _applying = false;
          _applyError = e;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.backupPreviewTitle)),
      body: FutureBuilder<ImportPlan>(
        future: _plan,
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsetsDirectional.all(24),
                child: Text(l10n.backupImportFailed('${snap.error}')),
              ),
            );
          }
          final plan = snap.data;
          if (plan == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(l10n.backupScanning),
                ],
              ),
            );
          }
          return _body(context, plan);
        },
      ),
      bottomNavigationBar: FutureBuilder<ImportPlan>(
        future: _plan,
        builder: (context, snap) {
          final plan = snap.data;
          final canImport =
              plan != null &&
              !_applying &&
              (plan.changesData ||
                  (_applySettings && plan.settingChanges.isNotEmpty));
          return SafeArea(
            child: Padding(
              padding: const EdgeInsetsDirectional.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _applying
                        ? null
                        : () => Navigator.of(context).pop(false),
                    child: Text(l10n.cancel),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    key: const ValueKey('backup-import-apply'),
                    onPressed: canImport ? () => unawaited(_apply(plan)) : null,
                    child: Text(l10n.backupImportButton),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _body(BuildContext context, ImportPlan plan) {
    final l10n = context.l10n;
    Widget count(IconData icon, String text) =>
        ListTile(leading: Icon(icon), title: Text(text), dense: true);
    final empty = !plan.changesData && plan.settingChanges.isEmpty;
    return ListView(
      children: [
        if (_applyError != null)
          ListTile(
            leading: Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(l10n.backupImportFailed('$_applyError')),
          ),
        if (_applying) const LinearProgressIndicator(),
        if (empty) ListTile(title: Text(l10n.backupPreviewNothing)),
        count(Icons.image_search, l10n.backupPreviewMatched(plan.matched)),
        count(
          Icons.label_outline,
          l10n.backupPreviewNewTags(plan.newTags.length),
        ),
        if (plan.reusedTags > 0)
          count(
            Icons.label_off_outlined,
            l10n.backupPreviewReusedTags(plan.reusedTags),
          ),
        count(Icons.tune, l10n.backupPreviewNewPresets(plan.newPresets.length)),
        if (plan.skippedPresets > 0)
          count(
            Icons.tune_outlined,
            l10n.backupPreviewSkippedPresets(plan.skippedPresets),
          ),
        count(
          Icons.sell_outlined,
          l10n.backupPreviewFileTags(plan.fileTagsToAdd.length),
        ),
        count(
          Icons.favorite_border,
          l10n.backupPreviewFavorites(plan.favoritesToAdd.length),
        ),
        count(
          Icons.done_all,
          l10n.backupPreviewReviewed(plan.reviewedToAdd.length),
        ),
        const Divider(),
        SwitchListTile(
          key: const ValueKey('backup-apply-settings'),
          title: Text(l10n.backupApplySettings),
          subtitle: Text(
            l10n.backupPreviewSettings(plan.settingChanges.length),
          ),
          value: _applySettings,
          onChanged: _applying || plan.settingChanges.isEmpty
              ? null
              : (v) => setState(() => _applySettings = v),
        ),
        if (plan.settingChanges.isNotEmpty)
          ExpansionTile(
            title: Text(l10n.backupPreviewSettings(plan.settingChanges.length)),
            children: [
              for (final s in plan.settingChanges)
                ListTile(dense: true, title: Text(s.name)),
            ],
          ),
        if (plan.unmatched.isNotEmpty)
          ExpansionTile(
            key: const ValueKey('backup-unmatched'),
            leading: const Icon(Icons.help_outline),
            title: Text(l10n.backupPreviewUnmatched(plan.unmatched.length)),
            children: [
              for (final f in plan.unmatched.take(_listLimit))
                ListTile(
                  dense: true,
                  title: Text(
                    l10n.backupPreviewFilePath(f.rel, f.name),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              if (plan.unmatched.length > _listLimit)
                ListTile(
                  dense: true,
                  title: Text(
                    l10n.backupPreviewUnmatchedMore(
                      plan.unmatched.length - _listLimit,
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}
