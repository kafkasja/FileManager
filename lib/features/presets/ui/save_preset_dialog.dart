import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/features/presets/data/preset_repository.dart';
import 'package:kfm/features/presets/domain/preset.dart';
import 'package:kfm/features/swipe/domain/swipe_action.dart';

/// P6 "Save as preset…": name + (when there is one) include the filter.
/// Saves without switching. Returns the new id, or null when cancelled.
Future<int?> showSavePresetDialog(
  BuildContext context, {
  required SwipeLayout layout,
  String? filterJson,
  String initialName = '',
}) => showDialog<int>(
  context: context,
  builder: (_) => _SavePresetDialog(
    layout: layout,
    filterJson: filterJson,
    initialName: initialName,
  ),
);

class _SavePresetDialog extends ConsumerStatefulWidget {
  const new({
    required this.layout,
    required this.filterJson,
    required this.initialName,
  });

  final SwipeLayout layout;
  final String? filterJson;
  final String initialName;

  @override
  ConsumerState<_SavePresetDialog> createState() => _SavePresetDialogState();
}

class _SavePresetDialogState extends ConsumerState<_SavePresetDialog> {
  late final _name = TextEditingController(text: widget.initialName);
  bool _includeFilter = true;
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    setState(() => _saving = true);
    try {
      final id = await ref
          .read(presetRepositoryProvider)
          .create(
            name: _name.text,
            layout: widget.layout,
            filterJson: _includeFilter ? widget.filterJson : null,
          );
      if (mounted) Navigator.of(context).pop(id);
    } on PresetNameException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = switch (e.problem) {
          PresetNameProblem.taken => l10n.presetNameTaken,
          PresetNameProblem.invalid => l10n.presetNameInvalid,
        };
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.presetSaveAs),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _name,
            autofocus: true,
            maxLength: kPresetNameMax,
            decoration: InputDecoration(
              labelText: l10n.presetNameLabel,
              errorText: _error,
            ),
            onSubmitted: (_) => _save(),
          ),
          if (widget.filterJson != null)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.presetIncludeFilter),
              value: _includeFilter,
              onChanged: (v) => setState(() => _includeFilter = v),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(l10n.presetEditorSave),
        ),
      ],
    );
  }
}
