import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/theme/app_tokens.dart';
import 'package:kfm/features/rename/data/rename_planner.dart';
import 'package:kfm/features/rename/data/rename_providers.dart';
import 'package:kfm/features/rename/domain/name_pattern.dart';
import 'package:kfm/features/swipe/ui/swipe_deck_controller.dart';
import 'package:kfm/l10n/generated/app_localizations.dart';

/// Pick a name pattern, preview every new name, apply (TASK-P3). Opened
/// from the "✎ N" pill on the swipe screen.
class RenameBatchScreen extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<RenameBatchScreen> createState() => _RenameBatchScreenState();
}

class _RenameBatchScreenState extends ConsumerState<RenameBatchScreen> {
  final _template = TextEditingController();
  int _start = 1;
  int _padding = 3;
  int? _batchId;
  RenamePreview? _preview;
  Timer? _debounce;
  int _requests = 0;

  NamePattern get _pattern =>
      NamePattern(template: _template.text, start: _start, padding: _padding);

  @override
  void initState() {
    super.initState();
    _template.addListener(_schedule);
    unawaited(_load());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _template.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final sessionId = ref.read(swipeDeckControllerProvider).value?.session.id;
    if (sessionId == null) return;
    final batch = await ref
        .read(renameBatchRepositoryProvider)
        .collecting(sessionId);
    if (!mounted) return;
    setState(() => _batchId = batch?.id);
    await _refresh();
  }

  void _schedule() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), () {
      unawaited(_refresh());
    });
  }

  Future<void> _refresh() async {
    final batchId = _batchId;
    if (batchId == null) return;
    final request = ++_requests;
    final preview = await ref
        .read(renamePlannerProvider)
        .preview(batchId, _pattern);
    // Only the newest request wins (typing fast).
    if (mounted && request == _requests) setState(() => _preview = preview);
  }

  Future<void> _apply() async {
    final batchId = _batchId;
    final preview = _preview;
    final sessionId = ref.read(swipeDeckControllerProvider).value?.session.id;
    if (batchId == null || preview == null || sessionId == null) return;
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    // showDialog uses the root navigator; the screen lives in the tab's.
    final dialogs = Navigator.of(context, rootNavigator: true);
    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => PopScope(
          canPop: false,
          child: AlertDialog(
            content: Row(
              children: [
                const CircularProgressIndicator(),
                const SizedBox(width: 24),
                Text(l10n.renameRunning),
              ],
            ),
          ),
        ),
      ),
    );
    final result = await ref
        .read(renameRunnerProvider)
        .apply(sessionId, batchId, _pattern, preview.newNames);
    dialogs.pop(); // progress dialog
    final text = result.declined
        ? l10n.renameDeclined
        : result.skipped > 0
        ? l10n.renameDoneSkipped(result.renamed, result.skipped)
        : l10n.renameDone(result.renamed);
    messenger.showSnackBar(SnackBar(content: Text(text)));
    if (!result.declined && mounted) navigator.pop();
  }

  Future<void> _discard() async {
    final batchId = _batchId;
    if (batchId == null) return;
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.renameDiscardTitle),
        content: Text(l10n.renameDiscardBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.renameDiscard),
          ),
        ],
      ),
    );
    if (!(ok ?? false)) return;
    await ref.read(renameBatchRepositoryProvider).discard(batchId);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final spacing = context.tokens.spacing;
    final preview = _preview;
    final error = preview?.error;
    final canApply =
        preview != null &&
        error == null &&
        preview.renamable > 0 &&
        _template.text.trim().isNotEmpty;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.renameTitle),
        actions: [
          IconButton(
            tooltip: l10n.renameDiscard,
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: _batchId == null ? null : _discard,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsetsDirectional.all(spacing * 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _template,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: l10n.renamePatternLabel,
                    hintText: l10n.renamePatternHint('{n}'),
                    helperText: l10n.renameTokensHelp(
                      '{n}',
                      '{date}',
                      '{orig}',
                    ),
                    errorText: _template.text.trim().isEmpty || error == null
                        ? null
                        : _errorText(l10n, error),
                  ),
                ),
                SizedBox(height: spacing),
                Row(
                  children: [
                    Expanded(
                      child: _NumberField(
                        label: l10n.renameStart,
                        value: _start,
                        min: 0,
                        max: 999999,
                        onChanged: (v) {
                          setState(() => _start = v);
                          _schedule();
                        },
                      ),
                    ),
                    SizedBox(width: spacing * 2),
                    Expanded(
                      child: _NumberField(
                        label: l10n.renamePadding,
                        value: _padding,
                        min: 1,
                        max: NamePattern.maxPadding,
                        onChanged: (v) {
                          setState(() => _padding = v);
                          _schedule();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: preview == null
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: preview.rows.length,
                    itemBuilder: (context, i) =>
                        _PreviewTile(row: preview.rows[i]),
                  ),
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsetsDirectional.all(spacing * 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.renameNoUndoAfterDone,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  SizedBox(height: spacing),
                  FilledButton(
                    onPressed: canApply ? _apply : null,
                    child: Text(l10n.renameApply),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _errorText(AppLocalizations l, PatternError e) => switch (e) {
    PatternError.empty => l.renameErrorEmpty,
    PatternError.invalidChars => l.renameErrorInvalid,
    PatternError.needsCounter => l.renameErrorNeedsCounter('{n}'),
    PatternError.tooLong => l.renameErrorTooLong,
  };
}

class _PreviewTile extends StatelessWidget {
  const new({required this.row});

  final RenamePreviewRow row;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = Theme.of(context).colorScheme;
    final newName = row.newName;
    return ListTile(
      dense: true,
      title: Text(
        row.item.currentName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: colors.onSurfaceVariant),
      ),
      subtitle: newName == null
          ? Text(l10n.renameMissing, style: TextStyle(color: colors.error))
          : Text(
              row.collision ? l10n.renameCollision(newName) : '→ $newName',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: row.collision ? colors.tertiary : colors.onSurface,
              ),
            ),
    );
  }
}

class _NumberField extends StatelessWidget {
  const new({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => TextFormField(
    initialValue: '$value',
    keyboardType: TextInputType.number,
    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    decoration: InputDecoration(labelText: label),
    onChanged: (text) {
      final v = int.tryParse(text);
      if (v != null && v >= min && v <= max) onChanged(v);
    },
  );
}
