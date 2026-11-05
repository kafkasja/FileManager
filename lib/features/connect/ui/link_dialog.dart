import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/theme/app_tokens.dart';
import 'package:kfm/features/connect/domain/connection_request.dart';
import 'package:kfm/features/connect/domain/link.dart';

/// The link dialog's answer. Everything but `decision` only matters for
/// `accepted`.
typedef LinkAnswer = ({
  ConnectionDecision decision,
  LinkPerms perms,
  bool remember,
  bool alwaysAllow,
});

/// The two "what may `device` do with my files" checkboxes (TASK-E1, the
/// user decision: both on by default, "you can check them off if you dont
/// want it"). The link dialog and the waiting screen both show them.
class LinkPermsChoice extends StatelessWidget {
  const new({
    required this.device,
    required this.perms,
    required this.onChanged,
    super.key,
  });

  final String device;
  final LinkPerms perms;
  final ValueChanged<LinkPerms> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CheckboxListTile(
          key: const ValueKey('link-let-see'),
          contentPadding: EdgeInsetsDirectional.zero,
          controlAffinity: ListTileControlAffinity.leading,
          value: perms.see,
          title: Text(l10n.linkLetSee(device)),
          subtitle: Text(l10n.linkLetSeeHint),
          onChanged: (v) => onChanged(perms.copyWith(see: v ?? false)),
        ),
        CheckboxListTile(
          key: const ValueKey('link-let-take'),
          contentPadding: EdgeInsetsDirectional.zero,
          controlAffinity: ListTileControlAffinity.leading,
          value: perms.takeFreely,
          title: Text(l10n.linkLetTake(device)),
          subtitle: Text(l10n.linkLetTakeHint),
          onChanged: (v) => onChanged(perms.copyWith(takeFreely: v ?? false)),
        ),
      ],
    );
  }
}

/// "`A` wants to connect" (TASK-E1, was N3's accept dialog): name,
/// platform, the 4 words, then the checkboxes "Let A see my files" and "Let A take
/// files without asking" (on), "Remember A" (on) and "Trust A" (off; N6 "Always
/// allow", only with Remember). OK has the focus: the user asked for "just
/// press ok" (the 4 words are shown above it). Pops with a [LinkAnswer];
/// the prompter closes it with null when the request ends elsewhere.
class LinkDialog extends StatefulWidget {
  const new({
    required this.request,
    required this.deadline,
    this.initial = const LinkPerms(),
    super.key,
  });

  final ConnectionRequest request;

  /// When the request times out (for the countdown).
  final DateTime deadline;

  /// A remembered device's stored choice; defaults otherwise.
  final LinkPerms initial;

  @override
  State<LinkDialog> createState() => _LinkDialogState();
}

class _LinkDialogState extends State<LinkDialog> {
  Timer? _tick;
  late LinkPerms _perms = widget.initial;
  bool _remember = true;
  bool _alwaysAllow = false;

  void _pop(ConnectionDecision decision) => Navigator.of(context).pop((
    decision: decision,
    perms: _perms,
    remember: _remember,
    alwaysAllow: _remember && _alwaysAllow,
  ));

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
    final left = widget.deadline
        .difference(DateTime.now())
        .inSeconds
        .clamp(0, 3600);
    return PopScope(
      canPop: false,
      child: AlertDialog(
        title: Text(
          r.remembered
              ? l10n.acceptTitleRemembered(r.clientName)
              : l10n.acceptTitle(r.clientName),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.acceptPlatform(r.clientPlatform)),
              SizedBox(height: spacing * 2),
              Text(l10n.pairCompareWords),
              SizedBox(height: spacing),
              // Fixed English words (fingerprint_words.dart, ARB-exempt).
              Text(
                r.words.join(' '),
                key: const ValueKey('accept-words'),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: spacing),
              LinkPermsChoice(
                device: r.clientName,
                perms: _perms,
                onChanged: (p) => setState(() => _perms = p),
              ),
              CheckboxListTile(
                key: const ValueKey('accept-remember'),
                contentPadding: EdgeInsetsDirectional.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: _remember,
                title: Text(l10n.rememberThisDevice),
                onChanged: (v) => setState(() => _remember = v ?? false),
              ),
              CheckboxListTile(
                key: const ValueKey('accept-always-allow'),
                contentPadding: EdgeInsetsDirectional.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: _remember && _alwaysAllow,
                enabled: _remember,
                title: Text(l10n.acceptAlwaysAllow),
                subtitle: Text(l10n.acceptAlwaysAllowHint),
                onChanged: (v) => setState(() => _alwaysAllow = v ?? false),
              ),
              SizedBox(height: spacing),
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
            key: const ValueKey('accept-decline'),
            onPressed: () => _pop(ConnectionDecision.declined),
            child: Text(l10n.acceptDecline),
          ),
          FilledButton(
            key: const ValueKey('accept-accept'),
            autofocus: true,
            onPressed: () => _pop(ConnectionDecision.accepted),
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
  }
}
