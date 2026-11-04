import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/features/tags/data/tag_providers.dart';
import 'package:kfm/features/tags/domain/tag.dart';

/// Rename and/or recolor [tag] (TASK-B9). Same rules as creating: 1–40
/// characters, no other tag with the same name in any case.
Future<void> showTagEditDialog(BuildContext context, Tag tag) =>
    showDialog<void>(
      context: context,
      builder: (_) => TagEditDialog(tag: tag),
    );

class TagEditDialog extends ConsumerStatefulWidget {
  const new({required this.tag, super.key});

  final Tag tag;

  @override
  ConsumerState<TagEditDialog> createState() => _TagEditDialogState();
}

class _TagEditDialogState extends ConsumerState<TagEditDialog> {
  late final _name = TextEditingController(text: widget.tag.name);
  late int _color = widget.tag.color;
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
    final repo = ref.read(tagRepositoryProvider);
    try {
      if (name != widget.tag.name) await repo.rename(widget.tag.id, name);
      if (_color != widget.tag.color) {
        await repo.recolor(widget.tag.id, _color);
      }
      if (mounted) Navigator.of(context).pop();
    } on TagNameTaken {
      if (mounted) {
        setState(() {
          _error = l10n.tagNameTaken;
          _saving = false;
        });
      }
    } on Object {
      if (mounted) {
        setState(() {
          _error = l10n.tagWriteError;
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      // Scrolls on short screens (a phone in landscape, big text).
      scrollable: true,
      title: Text(l10n.tagEditTitle),
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
          child: Text(l10n.tagSave),
        ),
      ],
    );
  }
}
