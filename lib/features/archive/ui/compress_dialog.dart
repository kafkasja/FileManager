import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/theme/app_tokens.dart';
import 'package:kfm/core/files/file_names.dart';
import 'package:kfm/core/files/file_op_exception.dart';
import 'package:kfm/features/browse/ui/widgets/browse_parts.dart';
import 'package:kfm/features/folders/ui/folder_picker_sheet.dart';

/// Where to write a new zip: its file name (ends with `.zip`) and folder.
typedef CompressTarget = ({String name, String folder});

/// The default zip name: [baseName] without its extension + `.zip`
/// (`photo.jpg` → `photo.zip`, folder `Holiday` → `Holiday.zip`).
String defaultZipName(String baseName, {bool isFolder = false}) {
  final base = isFolder ? baseName : splitExtension(baseName).$1;
  return '${base.isEmpty ? baseName : base}.zip';
}

/// TASK-B5's name prompt: the zip's name (prefilled) and folder (the current
/// one; "Save to…" opens B4's folder picker). Null when cancelled.
Future<CompressTarget?> showCompressDialog(
  BuildContext context, {
  required String initialName,
  required String initialFolder,
}) => showDialog<CompressTarget>(
  context: context,
  builder: (_) =>
      CompressDialog(initialName: initialName, initialFolder: initialFolder),
);

class CompressDialog extends StatefulWidget {
  const new({
    required this.initialName,
    required this.initialFolder,
    super.key,
  });

  final String initialName;
  final String initialFolder;

  @override
  State<CompressDialog> createState() => _CompressDialogState();
}

class _CompressDialogState extends State<CompressDialog> {
  late final TextEditingController _name = TextEditingController(
    text: widget.initialName,
  )..selection = _baseSelection(widget.initialName);
  late String _folder = widget.initialFolder;
  bool _invalid = false;

  static TextSelection _baseSelection(String text) {
    final dot = text.lastIndexOf('.');
    return TextSelection(
      baseOffset: 0,
      extentOffset: dot > 0 ? dot : text.length,
    );
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pickFolder() async {
    final picked = await showFolderPicker(
      context,
      title: context.l10n.archiveSaveToTitle,
    );
    if (picked != null && mounted) setState(() => _folder = picked);
  }

  void _submit() {
    var name = _name.text.trim();
    if (!name.toLowerCase().endsWith('.zip')) name = '$name.zip';
    var valid = name.length > '.zip'.length;
    try {
      validateFileName(name);
    } on FileOpException {
      valid = false;
    }
    if (!valid) {
      setState(() => _invalid = true);
      return;
    }
    Navigator.of(context).pop<CompressTarget>((name: name, folder: _folder));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final spacing = context.tokens.spacing;
    return AlertDialog(
      title: Text(l10n.archiveCompressTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _name,
            autofocus: true,
            decoration: InputDecoration(
              labelText: l10n.nameLabel,
              errorText: _invalid ? l10n.nameInvalid : null,
              errorMaxLines: 3,
            ),
            onChanged: (_) {
              if (_invalid) setState(() => _invalid = false);
            },
            onSubmitted: (_) => _submit(),
          ),
          SizedBox(height: spacing * 2),
          Row(
            children: [
              const Icon(Icons.folder_outlined),
              SizedBox(width: spacing),
              Expanded(
                child: Text(
                  l10n.archiveSaveIn(nameOfFolder(l10n, _folder)),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton(
              onPressed: () => unawaited(_pickFolder()),
              child: Text(l10n.archiveSaveTo),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(l10n.archiveCompressAction),
        ),
      ],
    );
  }
}
