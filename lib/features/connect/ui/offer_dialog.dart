import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/theme/app_tokens.dart';
import 'package:kfm/core/files/file_kind_resolver.dart';
import 'package:kfm/core/thumbs/thumbnail.dart';
import 'package:kfm/core/utils/format.dart';
import 'package:kfm/features/connect/data/path_guard.dart';

/// The offer dialog's answer (TASK-N12).
typedef OfferAnswer = ({
  bool accept,
  String folder,
  bool remember,
  bool alwaysAccept,
});

/// What the offer dialog shows: names and sizes only (no thumbnails:
/// untrusted bytes), the sender's 4 words and the target folder.
@immutable
class OfferDialogData {
  const new({
    required this.offerId,
    required this.senderName,
    required this.platform,
    required this.words,
    required this.names,
    required this.totalBytes,
    required this.defaultFolder,
    required this.deadline,
    required this.showRemember,
  });

  final String offerId;
  final String senderName;
  final String platform;
  final List<String> words;
  final List<String> names;
  final int totalBytes;
  final String defaultFolder;
  final DateTime deadline;

  /// False when the sender is already remembered.
  final bool showRemember;
}

/// Picks another folder; null = dismissed.
typedef OfferFolderPicker = Future<String?> Function(BuildContext context);

/// "<S> wants to send you N files" (TASK-N12): the first 5 names with type
/// icons, the total size, "Save to … · Change", "Remember <S>" (default
/// on, only for an unremembered sender), "Always accept files from <S>"
/// (default off), Decline (focused) / Accept and a countdown. Pops with an
/// [OfferAnswer]; the prompter pops it with null when the offer ends
/// elsewhere.
class OfferDialog extends StatefulWidget {
  const new({required this.data, required this.pickFolder, super.key});

  final OfferDialogData data;
  final OfferFolderPicker pickFolder;

  @override
  State<OfferDialog> createState() => _OfferDialogState();
}

class _OfferDialogState extends State<OfferDialog> {
  static const _shown = 5;
  Timer? _tick;
  late String _folder = widget.data.defaultFolder;
  late bool _remember = widget.data.showRemember;
  bool _always = false;
  bool _excluded = false;

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

  void _pop({required bool accept}) => Navigator.of(context).pop((
    accept: accept,
    folder: _folder,
    remember: _remember || !widget.data.showRemember,
    alwaysAccept: _always,
  ));

  Future<void> _change() async {
    final picked = await widget.pickFolder(context);
    if (picked == null || !mounted) return;
    setState(() {
      // Excluded locations (app data, trash) are refused.
      _excluded = PathGuard.isExcluded(picked);
      if (!_excluded) _folder = picked;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final spacing = context.tokens.spacing;
    final d = widget.data;
    final left = d.deadline.difference(DateTime.now()).inSeconds.clamp(0, 3600);
    final more = d.names.length - _shown;
    return PopScope(
      canPop: false,
      child: AlertDialog(
        title: Text(l10n.offerTitle(d.senderName, d.names.length)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (d.platform.isNotEmpty) Text(l10n.acceptPlatform(d.platform)),
              if (d.words.isNotEmpty) ...[
                SizedBox(height: spacing),
                Text(l10n.pairCompareWords),
                // Fixed English words (fingerprint_words.dart).
                Text(
                  d.words.join(' '),
                  key: const ValueKey('offer-words'),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              SizedBox(height: spacing),
              for (final name in d.names.take(_shown))
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsetsDirectional.zero,
                  leading: Icon(fileKindIcon(kindFor(null, name))),
                  // A name chosen by the other device: shown as is.
                  title: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              if (more > 0) Text(l10n.offerMore(more)),
              SizedBox(height: spacing),
              Text(l10n.offerSize(formatBytes(d.totalBytes))),
              SizedBox(height: spacing),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.offerSaveTo(_folder),
                      key: const ValueKey('offer-folder'),
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                  TextButton(
                    key: const ValueKey('offer-change-folder'),
                    onPressed: () => unawaited(_change()),
                    child: Text(l10n.offerChangeFolder),
                  ),
                ],
              ),
              if (_excluded)
                Text(
                  l10n.offerFolderExcluded,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              if (d.showRemember)
                CheckboxListTile(
                  key: const ValueKey('offer-remember'),
                  contentPadding: EdgeInsetsDirectional.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: _remember || _always,
                  enabled: !_always,
                  title: Text(l10n.offerRemember(d.senderName)),
                  onChanged: (v) => setState(() => _remember = v ?? false),
                ),
              CheckboxListTile(
                key: const ValueKey('offer-always'),
                contentPadding: EdgeInsetsDirectional.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: _always,
                title: Text(l10n.offerAlwaysAccept(d.senderName)),
                onChanged: (v) => setState(() => _always = v ?? false),
              ),
              SizedBox(height: spacing),
              Text(
                l10n.offerAutoDecline(left),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            key: const ValueKey('offer-decline'),
            autofocus: true,
            onPressed: () => _pop(accept: false),
            child: Text(l10n.offerDecline),
          ),
          FilledButton(
            key: const ValueKey('offer-accept'),
            onPressed: () => _pop(accept: true),
            child: Text(l10n.offerAccept),
          ),
        ],
      ),
    );
  }
}
