import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/theme/app_tokens.dart';
import 'package:kfm/core/platform/screen_awake.dart';
import 'package:kfm/features/connect/data/accept_gate.dart';
import 'package:kfm/features/connect/data/connect_providers.dart';
import 'package:kfm/features/connect/data/pairing_secret_store.dart';
import 'package:kfm/features/connect/data/share_server.dart';
import 'package:kfm/features/connect/domain/connection_request.dart';
import 'package:kfm/features/connect/domain/pairing.dart';
import 'package:kfm/features/connect/ui/accept_dialog.dart';
import 'package:kfm/features/connect/ui/share_server_controller.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// "Share this device" (TASK-N1). Sharing runs only while this screen is
/// open: it starts in `initState` and stops in `dispose`. The QR area is
/// filled by N2. The screen stays on while open.
class ShareScreen extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<ShareScreen> createState() => _ShareScreenState();
}

class _ShareScreenState extends ConsumerState<ShareScreen> {
  // Read once: `ref` can't be used in dispose.
  late final ShareServerController _controller;
  late final ScreenAwake _awake;
  late final AcceptGate _gate;
  StreamSubscription<AcceptGateEvent>? _gateSub;

  /// The request whose accept dialog is open.
  String? _dialogFor;

  @override
  void initState() {
    super.initState();
    _controller = ref.read(shareServerControllerProvider.notifier);
    _awake = ref.read(screenAwakeProvider);
    _gate = ref.read(acceptGateProvider);
    _gateSub = _gate.events.listen(_onGateEvent);
    _keepAwake(on: true);
    // After the first frame: providers may not be modified during build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.startSharing().ignore();
    });
  }

  @override
  void dispose() {
    _gateSub?.cancel().ignore();
    _controller.stopSharing().ignore();
    _keepAwake(on: false);
    super.dispose();
  }

  void _onGateEvent(AcceptGateEvent e) {
    if (!mounted) return;
    switch (e) {
      case AcceptRequested(:final request):
        unawaited(_showAcceptDialog(request));
      case AcceptClosed(:final request, :final decision):
        if (_dialogFor != request.requestId) return;
        // Ended elsewhere (timeout, the client's cancel): close the dialog.
        _dialogFor = null;
        Navigator.of(context, rootNavigator: true).pop();
        final l10n = context.l10n;
        final text = switch (decision) {
          ConnectionDecision.cancelled => l10n.acceptRequestCancelled,
          ConnectionDecision.timedOut => l10n.acceptTimedOut,
          _ => null,
        };
        if (text != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(text)));
        }
    }
  }

  Future<void> _showAcceptDialog(ConnectionRequest request) async {
    // Respects the system's silent mode; best effort.
    unawaited(HapticFeedback.mediumImpact().catchError((Object _) {}));
    unawaited(
      SystemSound.play(SystemSoundType.alert).catchError((Object _) {}),
    );
    _dialogFor = request.requestId;
    final decision = await showDialog<ConnectionDecision>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AcceptDialog(
        request: request,
        deadline: request.receivedAt.add(_gate.timeout),
      ),
    );
    if (_dialogFor == request.requestId) _dialogFor = null;
    if (decision != null) _gate.decide(request.requestId, decision);
  }

  void _keepAwake({required bool on}) {
    // Best effort: a missing wakelock never blocks sharing.
    unawaited(_awake.keepOn(on: on).catchError((Object _) {}));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(shareServerControllerProvider);
    final spacing = context.tokens.spacing;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.shareTitle)),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsetsDirectional.all(spacing * 3),
          child: switch (state.status) {
            ShareServerStatus.starting => _Centered(
              icon: null,
              title: l10n.sharePreparing,
            ),
            ShareServerStatus.running => _Running(state: state),
            ShareServerStatus.error => _Centered(
              icon: Icons.wifi_off_outlined,
              title: state.error is NoLocalNetworkException
                  ? l10n.shareNoNetwork
                  : l10n.shareFailed,
              body: state.error is NoLocalNetworkException
                  ? l10n.shareNoNetworkHint
                  : null,
              action: FilledButton(
                onPressed: () => _controller.startSharing().ignore(),
                child: Text(l10n.shareRetry),
              ),
            ),
            ShareServerStatus.stopped => _Centered(
              icon: Icons.portable_wifi_off_outlined,
              title: l10n.shareStopped,
              action: FilledButton(
                onPressed: () => _controller.startSharing().ignore(),
                child: Text(l10n.shareStartAgain),
              ),
            ),
          },
        ),
      ),
    );
  }
}

class _Running extends ConsumerWidget {
  const new({required this.state});

  final ShareServerState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final spacing = context.tokens.spacing;
    final name = ref.watch(deviceIdentityProvider).value?.displayName ?? '';
    return ListView(
      children: [
        Text(
          l10n.shareSharing,
          style: theme.textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: spacing),
        Text(
          l10n.shareSharingAs(name),
          style: theme.textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: spacing * 2),
        const ConnectedClientsList(),
        const PairingPanel(),
        if (state.discoveryError != null) ...[
          SizedBox(height: spacing),
          Text(
            l10n.shareDiscoveryFailed,
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
        SizedBox(height: spacing * 2),
        Text(
          l10n.shareKeepOpen,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        if (kDebugMode) ...[
          SizedBox(height: spacing * 3),
          for (final a in state.addresses)
            SelectableText(
              l10n.shareDebugAddress(a.address.address, state.port ?? 0),
              key: ValueKey('share-address-${a.address.address}'),
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          if (state.fingerprint case final fp?)
            SelectableText(
              l10n.shareDebugFingerprint(fp),
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
        ],
        SizedBox(height: spacing * 4),
        Center(
          child: OutlinedButton.icon(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.stop_circle_outlined),
            label: Text(l10n.shareStop),
          ),
        ),
      ],
    );
  }
}

/// "Connected: `name`" + Disconnect per live session (TASK-N3).
class ConnectedClientsList extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final spacing = context.tokens.spacing;
    final clients = ref.watch(connectedClientsProvider).value ?? const [];
    if (clients.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsetsDirectional.only(bottom: spacing * 2),
      child: Column(
        children: [
          for (final c in clients)
            Card(
              child: ListTile(
                key: ValueKey('share-client-${c.sessionId}'),
                leading: const Icon(Icons.devices_outlined),
                title: Text(l10n.shareConnectedTo(c.clientName)),
                trailing: TextButton(
                  onPressed: () =>
                      ref.read(clientSessionStoreProvider).revoke(c.sessionId),
                  child: Text(l10n.shareDisconnectClient),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// QR + typed code + address + countdown (TASK-N2). Listens to the
/// [PairingSecretStore] directly so every rotation hint is shown.
class PairingPanel extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<PairingPanel> createState() => _PairingPanelState();
}

class _PairingPanelState extends ConsumerState<PairingPanel> {
  late final PairingSecretStore _store;
  StreamSubscription<PairingSecretState>? _sub;
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _store = ref.read(pairingSecretStoreProvider);
    _sub = _store.changes.listen(_onChange);
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    _sub?.cancel().ignore();
    super.dispose();
  }

  void _onChange(PairingSecretState s) {
    if (!mounted) return;
    if (s case SecretRotated(
      reason: RotationReason.qrLocked || RotationReason.codeLocked,
    )) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(context.l10n.shareRotatedLocked)),
        );
    }
    setState(() {});
  }

  static String _mmss(Duration d) {
    final s = d.isNegative ? 0 : d.inSeconds;
    return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final spacing = context.tokens.spacing;
    final state = _store.state;
    if (state is! SecretActive) {
      return const Center(child: CircularProgressIndicator());
    }
    final now = _store.now();
    final address = state.offer.addresses.firstOrNull;
    final cooldown = state.codeCooldownUntil;
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Column(
      children: [
        Text(l10n.shareQrHint, textAlign: TextAlign.center),
        SizedBox(height: spacing),
        Center(
          child: Semantics(
            label: l10n.shareQrSemantics,
            image: true,
            child: ExcludeSemantics(
              child: QrImageView(
                key: const ValueKey('share-qr'),
                data: state.offer.toUri(),
                size: 260,
                // White quiet zone also in dark mode, or scanners fail.
                backgroundColor: Colors.white,
                padding: EdgeInsets.all(spacing * 2),
                errorCorrectionLevel: QrErrorCorrectLevel.M,
              ),
            ),
          ),
        ),
        SizedBox(height: spacing),
        Text(
          l10n.shareExpiresIn(_mmss(state.expiresAt.difference(now))),
          style: muted,
        ),
        SizedBox(height: spacing * 3),
        Text(l10n.shareTypeCodeTitle, style: theme.textTheme.titleMedium),
        SizedBox(height: spacing),
        if (!state.typedCodesEnabled)
          Text(
            l10n.shareTypedCodesOff,
            key: const ValueKey('share-typed-off'),
            textAlign: TextAlign.center,
          )
        else ...[
          SelectableText(
            state.code.display,
            key: const ValueKey('share-code'),
            style: theme.textTheme.displaySmall?.copyWith(
              fontFamily: 'monospace',
              letterSpacing: 4,
            ),
          ),
          if (cooldown != null)
            Text(
              l10n.shareCodeCooldown(
                cooldown.difference(now).inSeconds.clamp(1, 30),
              ),
              textAlign: TextAlign.center,
            )
          else
            Text(
              l10n.shareExpiresIn(_mmss(state.codeExpiresAt.difference(now))),
              style: muted,
            ),
        ],
        if (address != null) ...[
          SizedBox(height: spacing),
          SelectableText(
            l10n.shareAddress('${address.host}:${address.port}'),
            key: const ValueKey('share-address'),
            style: theme.textTheme.titleSmall,
          ),
        ],
        SizedBox(height: spacing),
        Text(
          l10n.sharePrivacyNote,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _Centered extends StatelessWidget {
  const new({required this.icon, required this.title, this.body, this.action});

  /// Null shows a progress indicator.
  final IconData? icon;
  final String title;
  final String? body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = context.tokens.spacing;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon case final i?)
            Icon(i, size: 48, color: theme.colorScheme.onSurfaceVariant)
          else
            const CircularProgressIndicator(),
          SizedBox(height: spacing * 2),
          Text(
            title,
            style: theme.textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          if (body case final b?) ...[
            SizedBox(height: spacing),
            Text(b, textAlign: TextAlign.center),
          ],
          if (action case final a?) ...[SizedBox(height: spacing * 2), a],
        ],
      ),
    );
  }
}
