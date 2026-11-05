import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/safe_nav.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/features/connect/data/accept_gate.dart';
import 'package:kfm/features/connect/data/connect_providers.dart';
import 'package:kfm/features/connect/data/take_gate.dart';
import 'package:kfm/features/connect/domain/connection_request.dart';
import 'package:kfm/features/connect/domain/known_device.dart';
import 'package:kfm/features/connect/domain/link.dart';
import 'package:kfm/features/connect/ui/link_controller.dart';
import 'package:kfm/features/connect/ui/link_dialog.dart';
import 'package:kfm/features/connect/ui/take_prompt_dialog.dart';

/// TASK-E1, mounted once in the app shell (phone and desktop). Draws
/// nothing. While this device's server runs (the Connect screen, or a
/// link after leaving it) it shows, on any screen:
/// - the link dialog for a pairing request ([AcceptGate], N3's prompt);
///   OK stores this side's perms before the token is issued;
/// - the take prompt for a peer that may not take files without asking
///   ([TakeGate]).
/// A request that ends elsewhere (timeout, cancel, stop) closes its dialog
/// through a [DialogHandle] (never a blind pop).
class LinkPrompter extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<LinkPrompter> createState() => _LinkPrompterState();
}

class _LinkPrompterState extends ConsumerState<LinkPrompter> {
  StreamSubscription<AcceptGateEvent>? _acceptSub;
  StreamSubscription<TakeGateEvent>? _takeSub;
  late final AcceptGate _gate;
  late final TakeGate _takes;

  String? _linkDialogFor;
  final DialogHandle<LinkAnswer> _linkDialog = DialogHandle();
  String? _takeDialogFor;
  final DialogHandle<TakeAnswer> _takeDialog = DialogHandle();

  @override
  void initState() {
    super.initState();
    _gate = ref.read(acceptGateProvider);
    _takes = ref.read(takeGateProvider);
    _acceptSub = _gate.events.listen(_onAccept);
    _takeSub = _takes.events.listen(_onTake);
    // A prompt that started before this widget (hot restart, a rebuilt
    // shell) still shows.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_gate.pending case final r?) _onAccept(AcceptRequested(r));
      if (_takes.current case final t?) _onTake(TakeRequested(t));
    });
  }

  @override
  void dispose() {
    _acceptSub?.cancel().ignore();
    _takeSub?.cancel().ignore();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();

  void _alert() {
    // Respects the system's silent mode; best effort.
    unawaited(HapticFeedback.mediumImpact().catchError((Object _) {}));
    unawaited(
      SystemSound.play(SystemSoundType.alert).catchError((Object _) {}),
    );
  }

  void _snack(String text) {
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(persist: false, content: Text(text)));
  }

  // ---- connection requests ----------------------------------------------

  void _onAccept(AcceptGateEvent e) {
    if (!mounted) return;
    switch (e) {
      case AcceptRequested(:final request):
        if (_linkDialogFor == request.requestId) return;
        unawaited(_showLinkDialog(request));
      case AutoAccepted(:final request):
        // N6 "Always allow" / a trusted device: no prompt, just a note.
        _snack(context.l10n.shareAutoAccepted(request.clientName));
      case AcceptClosed(:final request, :final decision):
        if (_linkDialogFor != request.requestId) return;
        // Ended elsewhere (timeout, the client's cancel): close the dialog.
        _linkDialogFor = null;
        _linkDialog.close();
        final l10n = context.l10n;
        final text = switch (decision) {
          ConnectionDecision.cancelled => l10n.acceptRequestCancelled,
          ConnectionDecision.timedOut => l10n.acceptTimedOut,
          _ => null,
        };
        if (text != null) _snack(text);
    }
  }

  Future<void> _showLinkDialog(ConnectionRequest request) async {
    _alert();
    _linkDialogFor = request.requestId;
    final link = ref.read(linkControllerProvider.notifier);
    final initial = request.remembered
        ? await link.storedPerms(request.clientFingerprint)
        : const LinkPerms();
    if (!mounted || _linkDialogFor != request.requestId) return;
    final answer = await _linkDialog.show(
      context,
      barrierDismissible: false,
      builder: (_) => LinkDialog(
        request: request,
        initial: initial,
        deadline: request.receivedAt.add(_gate.timeout),
      ),
    );
    if (_linkDialogFor == request.requestId) _linkDialogFor = null;
    if (answer == null) return;
    final fp = request.clientFingerprint;
    final accepted = answer.decision == ConnectionDecision.accepted;
    // Before the decision: the token's roots come from these perms.
    if (accepted) ref.read(linkPermsStoreProvider).set(fp, answer.perms);
    if (!_gate.decide(request.requestId, answer.decision) || !accepted) {
      return;
    }
    if (answer.remember) {
      final repo = ref.read(knownDevicesRepositoryProvider);
      // N6 + E1. Ordered in the write queue: the row first, then its perms.
      repo
          .saveAfterPairing(
            PairedPeer(
              fingerprint: fp,
              peerDeviceId: request.clientDeviceId,
              name: request.clientName,
              platform: request.clientPlatform,
              autoAccept: answer.alwaysAllow,
            ),
            temporary: false,
          )
          // A failure shows through the write queue's error stream.
          .then<void>((_) {}, onError: (Object _) {})
          .ignore();
      repo
          .setLinkPerms(
            fp,
            see: answer.perms.see,
            takeFreely: answer.perms.takeFreely,
          )
          .fireAndForget();
    }
  }

  // ---- take prompts -------------------------------------------------------

  void _onTake(TakeGateEvent e) {
    if (!mounted) return;
    switch (e) {
      case TakeRequested(:final request):
        if (_takeDialogFor == request.id) return;
        unawaited(_showTake(request));
      case TakeClosed(:final request, :final decision):
        if (_takeDialogFor != request.id) return;
        _takeDialogFor = null;
        _takeDialog.close();
        if (decision == TakeDecision.timedOut) {
          _snack(context.l10n.takePromptTimedOut(request.peerName));
        }
    }
  }

  Future<void> _showTake(TakeRequest request) async {
    _alert();
    _takeDialogFor = request.id;
    final answer = await _takeDialog.show(
      context,
      barrierDismissible: false,
      builder: (_) => TakePromptDialog(
        request: request,
        deadline: request.receivedAt.add(_takes.timeout),
      ),
    );
    if (_takeDialogFor == request.id) _takeDialogFor = null;
    if (answer == null) return;
    final fp = request.peerFingerprint;
    if (answer.allow && answer.always) {
      // "Always allow": take without asking from now on (stored when the
      // device is remembered).
      final perms =
          ref.read(linkPermsStoreProvider).of(fp) ?? const LinkPerms();
      await ref
          .read(linkControllerProvider.notifier)
          .applyPerms(fp, perms.copyWith(takeFreely: true), persist: true);
    }
    _takes.decide(request.id, allow: answer.allow);
  }
}
