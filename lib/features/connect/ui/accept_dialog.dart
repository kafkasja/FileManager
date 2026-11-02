import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/theme/app_tokens.dart';
import 'package:kfm/features/connect/domain/connection_request.dart';

/// The accept dialog's answer. `remember` and `alwaysAllow` only matter
/// for `accepted` (N6).
typedef AcceptAnswer = ({
  ConnectionDecision decision,
  bool remember,
  bool alwaysAllow,
});

/// "X wants to connect" (TASK-N3): a blocking dialog with the client's name,
/// platform and the 4-word phrase. Decline has the default focus (no reflex
/// Accept). Pops with an [AcceptAnswer] (`accepted` or `declined`); the
/// share screen pops it with null when the request ends elsewhere (timeout,
/// cancel, stop). N4 opens its folder picker after Accept. N6: "Remember
/// this device" (default on) and "Always allow this device" (default off,
/// only with Remember: later reconnects skip this dialog).
class AcceptDialog extends StatefulWidget {
  const new({required this.request, required this.deadline, super.key});

  final ConnectionRequest request;

  /// When the request times out (for the countdown).
  final DateTime deadline;

  @override
  State<AcceptDialog> createState() => _AcceptDialogState();
}

class _AcceptDialogState extends State<AcceptDialog> {
  Timer? _tick;
  bool _remember = true;
  bool _alwaysAllow = false;

  void _pop(ConnectionDecision decision) => Navigator.of(context).pop((
    decision: decision,
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
            autofocus: true,
            onPressed: () => _pop(ConnectionDecision.declined),
            child: Text(l10n.acceptDecline),
          ),
          FilledButton(
            key: const ValueKey('accept-accept'),
            onPressed: () => _pop(ConnectionDecision.accepted),
            child: Text(l10n.acceptAccept),
          ),
        ],
      ),
    );
  }
}
