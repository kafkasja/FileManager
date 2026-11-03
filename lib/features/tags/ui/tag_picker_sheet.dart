import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/adaptive_sheet.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/features/tags/data/tag_providers.dart';
import 'package:kfm/features/tags/domain/tag.dart';

/// Picks (or creates) a tag (TASK-P2; B9 reuses it). Returns its id, or null
/// when dismissed.
/// A dialog on the desktop (PL3).
Future<int?> showTagPicker(BuildContext context) => showAdaptiveSheet<int>(
  context: context,
  isScrollControlled: true,
  maxDialogWidth: 400,
  builder: (_) => const _TagPicker(),
);

/// Creates a tag (name + color). Returns it, or null when cancelled.
Future<Tag?> showNewTagDialog(BuildContext context) =>
    showDialog<Tag>(context: context, builder: (_) => const _NewTagDialog());

class _TagPicker extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final tags = ref.watch(tagsByIdProvider).value?.values.toList() ?? const [];
    return AdaptiveScrollSheet(
      builder: (context, scroll, {required shrinkWrap}) => ListView(
        controller: scroll,
        shrinkWrap: shrinkWrap,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 8),
            child: Text(
              l10n.tagPickerTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.new_label_outlined),
            title: Text(l10n.tagPickerNew),
            onTap: () async {
              final tag = await showNewTagDialog(context);
              if (tag != null && context.mounted) {
                Navigator.of(context).pop(tag.id);
              }
            },
          ),
          if (tags.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(l10n.tagsEmpty),
            ),
          for (final t in tags)
            ListTile(
              leading: Icon(Icons.label, color: Color(t.color)),
              title: Text(t.name),
              onTap: () => Navigator.of(context).pop(t.id),
            ),
        ],
      ),
    );
  }
}

class _NewTagDialog extends ConsumerStatefulWidget {
  const new();

  @override
  ConsumerState<_NewTagDialog> createState() => _NewTagDialogState();
}

class _NewTagDialogState extends ConsumerState<_NewTagDialog> {
  final _name = TextEditingController();
  int _color = kTagColors.first;
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    final name = _name.text.trim();
    if (name.isEmpty || name.length > kTagNameMax) {
      setState(() => _error = l10n.tagNameInvalid);
      return;
    }
    setState(() => _saving = true);
    try {
      final tag = await ref.read(tagRepositoryProvider).create(name, _color);
      if (mounted) Navigator.of(context).pop(tag);
    } on TagNameTaken {
      if (mounted) {
        setState(() {
          _error = l10n.tagNameTaken;
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.tagNewTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _name,
            autofocus: true,
            maxLength: kTagNameMax,
            decoration: InputDecoration(
              hintText: l10n.tagNameHint,
              errorText: _error,
            ),
            onSubmitted: (_) => _submit(),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in kTagColors)
                InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => setState(() => _color = c),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: Color(c),
                    child: c == _color
                        ? const Icon(Icons.check, size: 18, color: Colors.white)
                        : null,
                  ),
                ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: Text(l10n.create),
        ),
      ],
    );
  }
}
