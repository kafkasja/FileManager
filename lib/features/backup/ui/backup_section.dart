import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/features/backup/data/backup_providers.dart';
import 'package:kfm/features/backup/domain/backup_codec.dart';
import 'package:kfm/features/backup/ui/import_preview_screen.dart';
import 'package:kfm/l10n/generated/app_localizations.dart';
import 'package:path/path.dart' as p;

/// Settings → Backup (TASK-X6): Export, Import, Undo last import.
class BackupSection extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<BackupSection> createState() => _BackupSectionState();
}

class _BackupSectionState extends ConsumerState<BackupSection> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() job) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await job();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _snack(String text, {SnackBarAction? action}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        action == null
            ? SnackBar(content: Text(text))
            : SnackBar(content: Text(text), action: action, persist: false),
      );
  }

  Future<File> _tempFile(String name) async {
    final dir = await ref.read(backupCacheDirProvider.future);
    return File(p.join(dir.path, name));
  }

  Future<void> _export() => _run(() async {
    final l10n = context.l10n;
    final service = ref.read(backupServiceProvider);
    final docs = ref.read(backupDocumentsProvider);
    File? tmp;
    try {
      final name = service.suggestedFileName();
      final uri = await docs.createDocument(name, 'application/json');
      if (uri == null) return;
      tmp = await _tempFile('export.json');
      await tmp.writeAsString(await service.exportJson(), flush: true);
      await docs.writeDocument(uri, tmp.path);
      _snack(l10n.backupExported);
    } on Object catch (e) {
      _snack(l10n.backupExportFailed(e.toString()));
    } finally {
      if (tmp != null && tmp.existsSync()) await tmp.delete();
    }
  });

  Future<void> _import() => _run(() async {
    final l10n = context.l10n;
    final service = ref.read(backupServiceProvider);
    final docs = ref.read(backupDocumentsProvider);
    final BackupData data;
    File? tmp;
    try {
      final uri = await docs.openDocument(const ['application/json', '*/*']);
      if (uri == null) return;
      tmp = await _tempFile('import.json');
      await docs.readDocument(uri, tmp.path);
      data = await service.decode(await tmp.readAsString());
    } on BackupFormatException catch (e) {
      _snack(switch (e.problem) {
        BackupProblem.notBackup => l10n.backupNotKfm,
        BackupProblem.tooNew => l10n.backupTooNew,
      });
      return;
    } on FileSystemException {
      // Not UTF-8 text (readAsString) or unreadable: not a backup.
      _snack(l10n.backupNotKfm);
      return;
    } on Object catch (e) {
      _snack(l10n.backupImportFailed(e.toString()));
      return;
    } finally {
      if (tmp != null && tmp.existsSync()) await tmp.delete();
    }
    if (!mounted) return;
    final imported = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ImportPreviewScreen(data: data)),
    );
    if (imported != true || !mounted) return;
    ref.invalidate(backupUndoAvailableProvider);
    // The snackbar outlives this (lazily built) section: capture everything.
    final undo = _undoer();
    _snack(
      l10n.backupImported,
      action: SnackBarAction(label: l10n.undo, onPressed: undo),
    );
  });

  /// Undoes the last import; safe to call after this widget is gone.
  VoidCallback _undoer() {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final container = ProviderScope.containerOf(context, listen: false);
    return () => unawaited(
      _undoImport(l10n, messenger, container).whenComplete(() {
        if (mounted) setState(() => _busy = false);
      }),
    );
  }

  Future<void> _undoImport(
    AppLocalizations l10n,
    ScaffoldMessengerState messenger,
    ProviderContainer container,
  ) async {
    if (mounted) setState(() => _busy = true);
    String text;
    try {
      await container.read(backupServiceProvider).undoLastImport();
      text = l10n.backupUndone;
    } on Object catch (e) {
      text = l10n.backupUndoFailed(e.toString());
    } finally {
      container.invalidate(backupUndoAvailableProvider);
    }
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _confirmUndo() async {
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(l10n.backupUndoConfirmTitle),
        content: Text(l10n.backupUndoConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(l10n.backupUndoConfirm),
          ),
        ],
      ),
    );
    if (ok == true && mounted) _undoer()();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final canUndo = ref.watch(backupUndoAvailableProvider).value ?? false;
    return Column(
      children: [
        ListTile(
          key: const ValueKey('backup-export'),
          leading: const Icon(Icons.save_alt_outlined),
          title: Text(l10n.backupExport),
          subtitle: Text(l10n.backupExportHelp),
          enabled: !_busy,
          onTap: () => unawaited(_export()),
        ),
        ListTile(
          key: const ValueKey('backup-import'),
          leading: const Icon(Icons.restore_outlined),
          title: Text(l10n.backupImport),
          subtitle: Text(l10n.backupImportHelp),
          enabled: !_busy,
          onTap: () => unawaited(_import()),
        ),
        if (canUndo)
          ListTile(
            key: const ValueKey('backup-undo'),
            leading: const Icon(Icons.undo),
            title: Text(l10n.backupUndoImport),
            subtitle: Text(l10n.backupUndoImportHelp),
            enabled: !_busy,
            onTap: () => unawaited(_confirmUndo()),
          ),
      ],
    );
  }
}
