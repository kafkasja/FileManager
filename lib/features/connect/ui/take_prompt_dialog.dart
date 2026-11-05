import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/theme/app_tokens.dart';
import 'package:kfm/core/files/file_kind_resolver.dart';
import 'package:kfm/core/thumbs/thumbnail.dart';
import 'package:kfm/core/utils/format.dart';
import 'package:kfm/features/connect/data/take_gate.dart';

/// The take prompt's answer: `allow`, and `always` = "take without
/// asking" from now on for that device.
typedef TakeAnswer = ({bool allow, bool always});

/// "`A` wants to take 3 files (412 MB)" (TASK-E1): which files, with name,
/// size and type, `[ ] Always allow A`, Decline / Allow. A move says the
/// originals go to the trash here. Decline has the focus (taking is the
/// risky answer). The prompter closes it with null when the request ends
/// elsewhere.
class TakePromptDialog extends StatefulWidget {
  const new({required this.request, required this.deadline, super.key});

  final TakeRequest request;
  final DateTime deadline;

  @override
  State<TakePromptDialog> createState() => _TakePromptDialogState();
}

class _TakePromptDialogState extends State<TakePromptDialog> {
  Timer? _tick;
  bool _always = false;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final spacing = context.tokens.spacing;
    final r = widget.request;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final total = formatBytes(r.totalBytes, locale: locale);
    final left = widget.deadline
        .difference(DateTime.now())
        .inSeconds
        .clamp(0, 3600);
    final height = MediaQuery.sizeOf(context).height;
    return PopScope(
      canPop: false,
      child: AlertDialog(
        key: const ValueKey('take-prompt'),
        title: Text(
          r.move
              ? l10n.takePromptMoveTitle(r.peerName, r.files.length, total)
              : l10n.takePromptTitle(r.peerName, r.files.length, total),
        ),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (r.move) ...[
                Text(l10n.takePromptMoveNote),
                SizedBox(height: spacing),
              ],
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: height * 0.4),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final f in r.files)
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsetsDirectional.zero,
                        leading: Icon(
                          fileKindIcon(kindFor(f.mimeType, f.name)),
                        ),
                        title: Text(
                          f.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          l10n.takePromptFileLine(
                            formatBytes(f.sizeBytes, locale: locale),
                            _type(f),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              CheckboxListTile(
                key: const ValueKey('take-always'),
                contentPadding: EdgeInsetsDirectional.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: _always,
                title: Text(l10n.takePromptAlways(r.peerName)),
                onChanged: (v) => setState(() => _always = v ?? false),
              ),
              Text(
                l10n.acceptAutoDecline(left),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            key: const ValueKey('take-decline'),
            autofocus: true,
            onPressed: () =>
                Navigator.of(context).pop((allow: false, always: false)),
            child: Text(l10n.acceptDecline),
          ),
          FilledButton(
            key: const ValueKey('take-allow'),
            onPressed: () =>
                Navigator.of(context).pop((allow: true, always: _always)),
            child: Text(l10n.takePromptAllow),
          ),
        ],
      ),
    );
  }

  /// "JPEG", "MP4"…: the extension, else the MIME subtype.
  static String _type(TakeFile f) {
    final dot = f.name.lastIndexOf('.');
    if (dot > 0 && dot < f.name.length - 1) {
      return f.name.substring(dot + 1).toUpperCase();
    }
    final mime = f.mimeType;
    if (mime != null && mime.contains('/')) {
      return mime.substring(mime.indexOf('/') + 1).toUpperCase();
    }
    return '—';
  }
}
