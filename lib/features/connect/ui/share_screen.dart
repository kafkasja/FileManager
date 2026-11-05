import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/router.dart';
import 'package:kfm/app/safe_nav.dart';
import 'package:kfm/app/theme/app_tokens.dart';
import 'package:kfm/core/platform/host_platform.dart';
import 'package:kfm/core/platform/permissions/storage_access_provider.dart';
import 'package:kfm/core/platform/screen_awake.dart';
import 'package:kfm/features/connect/data/accept_gate.dart';
import 'package:kfm/features/connect/data/connect_providers.dart';
import 'package:kfm/features/connect/data/pairing_secret_store.dart';
import 'package:kfm/features/connect/data/remote_trash_service.dart';
import 'package:kfm/features/connect/data/share_change_tracker.dart';
import 'package:kfm/features/connect/data/share_server.dart';
import 'package:kfm/features/connect/data/windows_share_check.dart';
import 'package:kfm/features/connect/domain/connection_request.dart';
import 'package:kfm/features/connect/domain/known_device.dart';
import 'package:kfm/features/connect/domain/pairing.dart';
import 'package:kfm/features/connect/ui/accept_dialog.dart';
import 'package:kfm/features/connect/ui/share_server_controller.dart';
import 'package:kfm/features/connect/ui/shared_folders_picker.dart';
import 'package:kfm/l10n/generated/app_localizations.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// A chunk stored this recently counts as a running upload (Q8: the
/// client sends the next one right away).
const Duration kShareActivityWindow = Duration(seconds: 15);

/// "Share this device" (TASK-N1). Sharing starts in `initState` and stops
/// in `dispose`; on Android it keeps running while KFM is in the background
/// (N5b notification). The QR area is
/// filled by N2. The screen stays on while open.
class ShareScreen extends ConsumerStatefulWidget {
  const new({this.receive = false, this.onStop, super.key});

  /// N12 "Receive files": the same server, headed "Ready to receive files".
  /// Send pairings never open the folder picker either way.
  final bool receive;

  /// Embedded mode (desktop Devices pane, TASK-E1): Stop sharing calls this
  /// instead of popping, and Back/Esc are left alone. The screen is not a
  /// route there, so a pop would remove the Devices branch's only page and
  /// leave a black pane.
  final VoidCallback? onStop;

  @override
  ConsumerState<ShareScreen> createState() => _ShareScreenState();
}

class _ShareScreenState extends ConsumerState<ShareScreen> {
  // Read once: `ref` can't be used in dispose.
  late final ShareServerController _controller;
  late final ScreenAwake _awake;
  late final AcceptGate _gate;
  late final ShareChangeTracker _tracker;
  WindowsShareCheck? _windowsCheck;
  StreamSubscription<AcceptGateEvent>? _gateSub;
  ProviderSubscription<ShareServerState>? _statusSub;
  ProviderSubscription<RemoteRequestOutcome?>? _outcomeSub;

  /// The request whose accept dialog is open.
  String? _dialogFor;
  final DialogHandle<AcceptAnswer> _dialog = DialogHandle();

  @override
  void initState() {
    super.initState();
    _controller = ref.read(shareServerControllerProvider.notifier);
    _awake = ref.read(screenAwakeProvider);
    _gate = ref.read(acceptGateProvider);
    _gateSub = _gate.events.listen(_onGateEvent);
    _tracker = ref.read(shareChangeTrackerProvider);
    // PL1: "Allow on private networks only" before the firewall prompt.
    _windowsCheck = ref.read(windowsShareCheckProvider)
      ?..explainFirewall = _explainFirewall;
    // N7 live sync: observe changes only while the server runs.
    _statusSub = ref.listenManual(
      shareServerControllerProvider,
      (_, next) {
        if (next.status == ShareServerStatus.running) {
          _tracker.start();
        } else {
          unawaited(_tracker.stop());
        }
      },
      // Sharing may already run (the screen was rebuilt).
      fireImmediately: true,
    );
    _outcomeSub = ref.listenManual(
      remoteRequestOutcomeStateProvider,
      (_, next) => _showOutcome(next),
    );
    _keepAwake(on: true);
    // After the first frame: providers may not be modified during build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.startSharing().ignore();
    });
  }

  Future<void> _explainFirewall() async {
    if (!mounted) return;
    final l10n = context.l10n;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.security_outlined),
        title: Text(l10n.shareFirewallTitle),
        content: Text(l10n.shareFirewallBody),
        actions: [
          FilledButton(
            autofocus: true,
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    if (_windowsCheck?.explainFirewall == _explainFirewall) {
      _windowsCheck?.explainFirewall = null;
    }
    _gateSub?.cancel().ignore();
    _statusSub?.close();
    _outcomeSub?.close();
    unawaited(_tracker.stop());
    _controller.stopSharing().ignore();
    _keepAwake(on: false);
    super.dispose();
  }

  void _onGateEvent(AcceptGateEvent e) {
    if (!mounted) return;
    switch (e) {
      case AcceptRequested(:final request):
        unawaited(_showAcceptDialog(request));
      case AutoAccepted(:final request):
        // N6 "Always allow": no prompt, just a note.
        _snack(
          context.l10n.shareAutoAccepted(request.clientName),
          change: request,
        );
      case AcceptClosed(:final request, :final decision):
        if (_dialogFor != request.requestId) return;
        // Ended elsewhere (timeout, the client's cancel): close the dialog.
        _dialogFor = null;
        _dialog.close();
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

  /// N7: "<B> moved N files to trash" / "You declined <B>'s request".
  void _showOutcome(RemoteRequestOutcome? o) {
    if (o == null || !mounted) return;
    if (!o.declined && o.kind != RemoteRequestKind.trash) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(remoteOutcomeText(context.l10n, o))),
      );
  }

  Future<void> _showAcceptDialog(ConnectionRequest request) async {
    // Respects the system's silent mode; best effort.
    unawaited(HapticFeedback.mediumImpact().catchError((Object _) {}));
    unawaited(
      SystemSound.play(SystemSoundType.alert).catchError((Object _) {}),
    );
    _dialogFor = request.requestId;
    final answer = await _dialog.show(
      context,
      barrierDismissible: false,
      builder: (_) => AcceptDialog(
        request: request,
        deadline: request.receivedAt.add(_gate.timeout),
      ),
    );
    if (_dialogFor == request.requestId) _dialogFor = null;
    if (answer == null) return;
    // The token is issued here; the client's root list follows the picker.
    if (!_gate.decide(request.requestId, answer.decision) ||
        answer.decision != ConnectionDecision.accepted ||
        !mounted) {
      return;
    }
    if (answer.remember) {
      // N6. Queued before any picker save, so the folders land on the row.
      ref
          .read(knownDevicesRepositoryProvider)
          .saveAfterPairing(
            PairedPeer(
              fingerprint: request.clientFingerprint,
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
    }
    var stored = StoredScope.empty;
    if (request.remembered) {
      try {
        stored = await ref.read(storedScopeLoaderProvider)(
          request.clientFingerprint,
        );
      } on Object {
        // The picker opens instead; nothing was seeded either.
      }
      if (!mounted) return;
    }
    final l10n = context.l10n;
    if (stored.roots.isNotEmpty) {
      // N6: a remembered device keeps its folders; no picker.
      _snack(
        stored.dropped
            ? l10n.shareFoldersMissing
            : l10n.shareRememberedFolders(stored.roots.length),
        change: request,
      );
      return;
    }
    if (stored.dropped) _snack(l10n.shareFoldersMissing);
    await showSharedFoldersPicker(
      context,
      clientFingerprint: request.clientFingerprint,
      clientName: request.clientName,
    );
  }

  /// A snackbar; with [change], a "Change" action opens that client's
  /// folder picker.
  void _snack(String text, {ConnectionRequest? change}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          persist: false,
          content: Text(text),
          action: change == null
              ? null
              : SnackBarAction(
                  label: context.l10n.shareFoldersChange,
                  onPressed: () {
                    if (!mounted) return;
                    unawaited(
                      showSharedFoldersPicker(
                        context,
                        clientFingerprint: change.clientFingerprint,
                        clientName: change.clientName,
                      ),
                    );
                  },
                ),
        ),
      );
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
    final embedded = widget.onStop != null;
    final scaffold = Scaffold(
      // Embedded: the Devices pane is the context, the title is the
      // heading below (E1: room for the QR).
      appBar: embedded
          ? null
          : AppBar(
              title: Text(widget.receive ? l10n.receiveFiles : l10n.shareTitle),
            ),
      body: SafeArea(
        child: Column(
          children: [
            const RemoteRequestBanner(),
            Expanded(
              child: _body(context, state, spacing, padding: spacing * 2),
            ),
          ],
        ),
      ),
    );
    // Embedded: not a route, nothing to pop (E1 H1).
    if (embedded) return scaffold;
    return PopScope(
      // Q8: leaving stops sharing; running transfers are asked about first.
      canPop: state.status != ShareServerStatus.running,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_leave());
      },
      child: scaffold,
    );
  }

  /// Q8: a download or upload stream runs, a chunk came in moments ago, or
  /// an N12 offer is pending / still receiving.
  bool _transfersActive() =>
      ref.read(clientSessionStoreProvider).hasActiveStreams ||
      ref.read(uploadStoreProvider).activeWithin(kShareActivityWindow) ||
      ref.read(offerServiceProvider).hasActiveOffers;

  /// Back / Stop sharing while sharing runs: asks first when transfers
  /// would be cut.
  Future<void> _leave() async {
    if (_transfersActive()) {
      final l10n = context.l10n;
      final stop = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          key: const ValueKey('share-stop-confirm'),
          title: Text(l10n.shareStopConfirmTitle),
          content: Text(l10n.shareStopConfirmBody),
          actions: [
            TextButton(
              autofocus: true,
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.shareKeepSharing),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.shareStop),
            ),
          ],
        ),
      );
      if (stop != true || !mounted) return;
    }
    if (widget.onStop case final onStop?) {
      onStop();
    } else {
      // A restored `/connect/share` may be the only page (E1 H3).
      safePop(context, fallback: AppRoutes.swipe);
    }
  }

  Widget _body(
    BuildContext context,
    ShareServerState state,
    double spacing, {
    required double padding,
  }) {
    final l10n = context.l10n;
    return Padding(
      padding: EdgeInsetsDirectional.all(padding),
      child: switch (state.status) {
        ShareServerStatus.starting => _Centered(
          icon: null,
          title: l10n.sharePreparing,
        ),
        ShareServerStatus.running => _Running(
          state: state,
          receive: widget.receive,
          onStop: () => unawaited(_leave()),
        ),
        ShareServerStatus.error when state.error is PublicNetworkException =>
          _Centered(
            icon: Icons.public_off_outlined,
            title: l10n.sharePublicNetwork,
            body: l10n.sharePublicNetworkHint,
            action: FilledButton(
              onPressed: () => _controller.startSharing().ignore(),
              child: Text(l10n.shareRetry),
            ),
          ),
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
    );
  }
}

/// Banner text: "<B> wants to move N files to trash" / "… to change N files".
String remoteNoticeText(AppLocalizations l, RemoteRequestNotice n) =>
    switch (n.kind) {
      RemoteRequestKind.trash => l.remoteTrashRequest(n.deviceName, n.count),
      RemoteRequestKind.writeAccess => l.remoteWriteRequest(
        n.deviceName,
        n.count,
      ),
    };

/// Snackbar text after a client's request (declined or trashed).
String remoteOutcomeText(AppLocalizations l, RemoteRequestOutcome o) =>
    o.declined
    ? l.remoteTrashDeclinedByYou(o.deviceName)
    : l.remoteTrashDone(o.deviceName, o.count);

/// TASK-N7: shown above the share screen while a client's trash or
/// write-access request runs (the system dialog is translucent, so it stays
/// visible behind it).
class RemoteRequestBanner extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notice = ref.watch(remoteRequestNoticeStateProvider);
    if (notice == null) return const SizedBox.shrink();
    return MaterialBanner(
      key: const ValueKey('share-remote-request'),
      leading: Icon(
        notice.kind == RemoteRequestKind.trash
            ? Icons.delete_outline
            : Icons.edit_outlined,
      ),
      content: Text(remoteNoticeText(context.l10n, notice)),
      actions: const [SizedBox.shrink()],
    );
  }
}

/// Below this width the QR and the text stack (one column).
const double kShareWideMinWidth = 720;

/// The QR's side stays between these (smaller only when the screen is
/// smaller still).
const double kShareQrMin = 140;
const double kShareQrMax = 360;

/// Running: everything fits on screen without scrolling (E1 issue 1: "dont
/// make it scrollable, it should all be on screen"). Wide (≥ 720 dp, or a
/// short landscape pane): QR at the start, the rest at the end. Narrow: one
/// column with the QR taking the space left. Notes collapse into an (i)
/// button when height is short. Only big text (L5, ≥ 1.5) scrolls.
class _Running extends ConsumerWidget {
  const new({required this.state, required this.onStop, this.receive = false});

  final ShareServerState state;
  final bool receive;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final spacing = context.tokens.spacing;
    final name = ref.watch(deviceIdentityProvider).value?.displayName ?? '';
    final mediaOnly =
        !(ref.watch(storageAccessControllerProvider).value?.canSeeAllFiles ??
            true);
    final bigText = MediaQuery.textScalerOf(context).scale(10) >= 15;
    return LayoutBuilder(
      builder: (context, c) {
        final wide =
            c.maxWidth >= kShareWideMinWidth ||
            (c.maxWidth >= 480 && c.maxWidth > c.maxHeight * 1.2);
        // Room for the notes under everything else.
        final notesInline = !bigText && c.maxHeight >= (wide ? 560 : 780);
        final header = <Widget>[
          Text(
            receive ? l10n.receiveReadyTitle : l10n.shareSharing,
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: spacing / 2),
          Text(
            receive ? l10n.receiveReadyHint(name) : l10n.shareSharingAs(name),
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: spacing),
          const ConnectedClientsList(),
          if (mediaOnly) ...[
            // N7: non-media files aren't indexed, so clients can't see them.
            Text(
              l10n.shareMediaOnlyHint,
              key: const ValueKey('share-media-only'),
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: spacing),
          ],
        ];
        final footer = <Widget>[
          if (state.discoveryError != null) ...[
            SizedBox(height: spacing),
            Text(
              l10n.shareDiscoveryFailed,
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
          if (notesInline) ...[
            SizedBox(height: spacing),
            Text(
              l10n.sharePrivacyNote,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: spacing),
            _KeepAliveNote(keepAlive: state.keepAlive),
          ],
          SizedBox(height: spacing),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: spacing,
            children: [
              OutlinedButton.icon(
                key: const ValueKey('share-stop'),
                onPressed: onStop,
                icon: const Icon(Icons.stop_circle_outlined),
                label: Text(l10n.shareStop),
              ),
              if (!notesInline || kDebugMode)
                IconButton(
                  key: const ValueKey('share-info'),
                  tooltip: l10n.shareInfoTooltip,
                  icon: const Icon(Icons.info_outline),
                  onPressed: () => unawaited(_showInfo(context, state)),
                ),
            ],
          ),
        ];
        return PairingPanel(
          header: header,
          footer: footer,
          wide: wide,
          scroll: bigText,
          // A short phone screen: the QR's own hint and countdown go.
          compact: !wide && c.maxHeight < 600,
        );
      },
    );
  }

  /// The notes that don't fit, plus (debug builds) addresses and the
  /// certificate fingerprint.
  static Future<void> _showInfo(BuildContext context, ShareServerState state) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final spacing = context.tokens.spacing;
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        key: const ValueKey('share-info-dialog'),
        scrollable: true,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.sharePrivacyNote),
            SizedBox(height: spacing * 2),
            _KeepAliveNote(keepAlive: state.keepAlive),
            if (kDebugMode) ...[
              SizedBox(height: spacing * 2),
              for (final a in state.addresses)
                SelectableText(
                  l10n.shareDebugAddress(a.address.address, state.port ?? 0),
                  key: ValueKey('share-address-${a.address.address}'),
                  style: theme.textTheme.titleMedium,
                ),
              if (state.fingerprint case final fp?)
                SelectableText(
                  l10n.shareDebugFingerprint(fp),
                  style: theme.textTheme.bodySmall,
                ),
            ],
          ],
        ),
        actions: [
          TextButton(
            autofocus: true,
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
  }
}

/// What ends sharing besides Stop. Q8: the notification is only promised
/// when notifications are allowed (Android 13+ may deny them); checked
/// again when KFM comes back (the user may have changed it).
class _KeepAliveNote extends ConsumerStatefulWidget {
  const new({required this.keepAlive});

  final ShareKeepAlive keepAlive;

  @override
  ConsumerState<_KeepAliveNote> createState() => _KeepAliveNoteState();
}

class _KeepAliveNoteState extends ConsumerState<_KeepAliveNote> {
  bool _notifications = true;
  AppLifecycleListener? _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _check);
    _check();
  }

  @override
  void dispose() {
    _lifecycle?.dispose();
    super.dispose();
  }

  void _check() {
    unawaited(
      ref.read(shareBackgroundProvider).notificationsAllowed().then((allowed) {
        if (mounted && allowed != _notifications) {
          setState(() => _notifications = allowed);
        }
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Text(
      switch (widget.keepAlive) {
        ShareKeepAlive.background when isWindowsHost =>
          l10n.shareKeepsRunningTray,
        ShareKeepAlive.background when !_notifications =>
          l10n.shareKeepsRunningNoNotification,
        ShareKeepAlive.background => l10n.shareKeepsRunning,
        ShareKeepAlive.whileAppOpen => l10n.shareKeepOpen,
        ShareKeepAlive.whileOnScreen => l10n.shareKeepOpenDesktop,
      },
      key: const ValueKey('share-keep-alive'),
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
      textAlign: TextAlign.center,
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
    final store = ref.read(clientSessionStoreProvider);
    return Padding(
      padding: EdgeInsetsDirectional.only(bottom: spacing * 2),
      child: Column(
        children: [
          for (final c in clients)
            Card(
              child: ListTile(
                key: ValueKey('share-client-${c.sessionId}'),
                // Q8: no heartbeat for a while: the client vanished (it may
                // still come back).
                leading: Icon(
                  store.isResponsive(c)
                      ? Icons.devices_outlined
                      : Icons.portable_wifi_off_outlined,
                ),
                title: Text(
                  !store.isResponsive(c)
                      ? l10n.shareClientGone(c.clientName)
                      : c.sendOnly
                      ? l10n.shareSessionSending(c.clientName)
                      : l10n.shareConnectedTo(c.clientName),
                ),
                // N12: a send-only session has no folders to pick.
                subtitle: c.sendOnly
                    ? null
                    : Text(
                        l10n.shareClientFolders(
                          ref
                                  .watch(
                                    shareScopeProvider(c.clientFingerprint),
                                  )
                                  .value
                                  ?.roots
                                  .length ??
                              0,
                        ),
                      ),
                onTap: c.sendOnly
                    ? null
                    : () => unawaited(
                        showSharedFoldersPicker(
                          context,
                          clientFingerprint: c.clientFingerprint,
                          clientName: c.clientName,
                        ),
                      ),
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

/// QR + typed code + address + countdown (TASK-N2), laid out to fit
/// (E1): [header] above, [footer] below, the QR sized by what is left.
/// Listens to the [PairingSecretStore] directly so every rotation hint is
/// shown.
class PairingPanel extends ConsumerStatefulWidget {
  const new({
    this.header = const [],
    this.footer = const [],
    this.wide = false,
    this.scroll = false,
    this.compact = false,
    super.key,
  });

  final List<Widget> header;
  final List<Widget> footer;

  /// Two columns: QR at the start, everything else at the end.
  final bool wide;

  /// Big text (L5): one scrolling column with a fixed-size QR.
  final bool scroll;

  /// Short screens: no hint above the QR, no QR countdown (the code's
  /// stays).
  final bool compact;

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

  Widget _qr(SecretActive state, double side) {
    final spacing = context.tokens.spacing;
    return Semantics(
      label: context.l10n.shareQrSemantics,
      image: true,
      child: ExcludeSemantics(
        child: QrImageView(
          key: const ValueKey('share-qr'),
          data: state.offer.toUri(),
          size: side,
          // White quiet zone also in dark mode, or scanners fail.
          backgroundColor: Colors.white,
          padding: EdgeInsets.all(side < 200 ? spacing : spacing * 2),
          errorCorrectionLevel: QrErrorCorrectLevel.M,
        ),
      ),
    );
  }

  /// The hint above the QR and the QR, sized to the space given.
  Widget _qrArea(SecretActive state) => LayoutBuilder(
    builder: (context, c) {
      final spacing = context.tokens.spacing;
      final hint = widget.compact ? 0.0 : 24.0;
      final gap = widget.compact ? 0.0 : spacing;
      final room = math.min(c.maxWidth, c.maxHeight - hint - gap);
      final side = room < kShareQrMin
          ? math.max(0, room).toDouble()
          : math.min(room, kShareQrMax);
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (!widget.compact) ...[
            SizedBox(
              height: hint,
              child: Text(
                context.l10n.shareQrHint,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(height: gap),
          ],
          _qr(state, side),
        ],
      );
    },
  );

  List<Widget> _codeBlock(SecretActive state) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final spacing = context.tokens.spacing;
    final now = _store.now();
    final address = state.offer.addresses.firstOrNull;
    final cooldown = state.codeCooldownUntil;
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return [
      if (!widget.compact) ...[
        Text(
          l10n.shareExpiresIn(_mmss(state.expiresAt.difference(now))),
          style: muted,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: spacing),
      ],
      Text(
        l10n.shareTypeCodeTitle,
        style: theme.textTheme.titleMedium,
        textAlign: TextAlign.center,
      ),
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
          textAlign: TextAlign.center,
          style:
              (widget.compact
                      ? theme.textTheme.titleLarge
                      : theme.textTheme.headlineMedium)
                  ?.copyWith(fontFamily: 'monospace', letterSpacing: 4),
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
            textAlign: TextAlign.center,
          ),
      ],
      if (address != null) ...[
        if (!widget.compact) SizedBox(height: spacing),
        SelectableText(
          l10n.shareAddress('${address.host}:${address.port}'),
          key: const ValueKey('share-address'),
          style: theme.textTheme.titleSmall,
          textAlign: TextAlign.center,
        ),
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.tokens.spacing;
    final state = _store.state;
    if (state is! SecretActive) {
      // Between codes: the heading and Stop stay.
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...widget.header,
          const Expanded(child: Center(child: CircularProgressIndicator())),
          ...widget.footer,
        ],
      );
    }
    final code = _codeBlock(state);
    if (widget.scroll) {
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ...widget.header,
            Text(context.l10n.shareQrHint, textAlign: TextAlign.center),
            SizedBox(height: spacing),
            Center(child: _qr(state, 240)),
            SizedBox(height: spacing),
            ...code,
            ...widget.footer,
          ],
        ),
      );
    }
    if (widget.wide) {
      return Row(
        children: [
          Expanded(child: _qrArea(state)),
          SizedBox(width: spacing * 3),
          Expanded(
            // A connected device's card or a hint may not fit a short
            // window: the text column then shrinks, it never scrolls.
            child: LayoutBuilder(
              builder: (context, c) => Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: SizedBox(
                    width: c.maxWidth,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [...widget.header, ...code, ...widget.footer],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...widget.header,
        Expanded(child: _qrArea(state)),
        SizedBox(height: spacing),
        ...code,
        ...widget.footer,
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
    // Scrolls when the pane is short (an 800 × 600 window).
    return Center(
      child: SingleChildScrollView(
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
      ),
    );
  }
}
