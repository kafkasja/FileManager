import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/router.dart';
import 'package:kfm/features/connect/data/connect_providers.dart';
import 'package:kfm/features/connect/data/remote_source_provider.dart';
import 'package:kfm/features/connect/domain/known_device.dart';
import 'package:kfm/features/connect/domain/remote_connection_state.dart';
import 'package:kfm/features/connect/ui/remote_connection_controller.dart';
import 'package:kfm/features/session/data/session_providers.dart';
import 'package:kfm/features/session/domain/remote_deck_root.dart';
import 'package:kfm/features/session/domain/session.dart';
import 'package:kfm/features/session/domain/session_source.dart';
import 'package:kfm/features/swipe/ui/swipe_deck_controller.dart';
import 'package:kfm/features/swipe/ui/swipe_screen.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'remote_swipe_screen.g.dart';

/// N8: the active swipe sessions on other devices, newest first.
@riverpod
Stream<List<Session>> remoteSwipeSessions(Ref ref) =>
    ref.watch(sessionRepositoryProvider).watchActiveRemote();

/// The name of the device [fp]: live while connected, else the one stored
/// with [session].
String _deviceName(WidgetRef ref, String fp, Session? session) =>
    switch (ref.watch(remoteConnectionControllerProvider)) {
      RemoteConnected(:final peerFingerprint, :final peerName)
          when peerFingerprint == fp && peerName.isNotEmpty =>
        peerName,
      _ => RemoteDeckRoot.decode(session?.filterJson)?.device ?? '',
    };

/// `/connect/swipe/:fp` (TASK-N8): the swipe screen on the device
/// [peerFingerprint]'s folder (the session "Swipe these" started).
class RemoteSwipeScreen extends ConsumerWidget {
  const new({required this.peerFingerprint, super.key});

  final String peerFingerprint;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sourceId = remoteSourceId(peerFingerprint);
    final session = ref
        .watch(swipeDeckForSourceProvider(sourceId))
        .value
        ?.session;
    return SwipeDeckScope(
      sourceId: sourceId,
      deviceName: _deviceName(ref, peerFingerprint, session),
      child: SwipeScreen(sourceId: sourceId),
    );
  }
}

/// N8: "Swipe these" on remote browse: swipe [root]'s folder on the device
/// [peerFingerprint] (continuing its session there, if any).
Future<void> openRemoteSwipe(
  BuildContext context,
  WidgetRef ref,
  String peerFingerprint,
  RemoteDeckRoot root,
) async {
  await startRemoteSwipe(ref, peerFingerprint, root);
  if (!context.mounted) return;
  await context.push(AppRoutes.connectSwipeFor(peerFingerprint));
}

/// N8: one row per active remote session (Connect screen): "Continue
/// swiping on <A>", paused while it isn't connected, and Discard (always;
/// the only way out for a device that was removed or changed its key).
class RemoteSwipeSessionsList extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(remoteSwipeSessionsProvider).value ?? const [];
    if (sessions.isEmpty) return const SizedBox.shrink();
    final known = <String>{
      for (final d in ref.watch(knownDevicesProvider).value ?? <KnownDevice>[])
        d.fingerprint,
    };
    return Column(
      children: [
        for (final s in sessions)
          if (peerOfSourceId(s.sourceId) case final fp?)
            _SessionTile(session: s, peerFingerprint: fp, known: known),
      ],
    );
  }
}

class _SessionTile extends ConsumerWidget {
  const new({
    required this.session,
    required this.peerFingerprint,
    required this.known,
  });

  final Session session;
  final String peerFingerprint;
  final Set<String> known;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final named = _deviceName(ref, peerFingerprint, session);
    final device = named.isEmpty ? l10n.remoteSwipeUnknownDevice : named;
    final connected = ref.watch(remotePeerConnectedProvider(peerFingerprint));
    final swiped = ref.watch(undoableCountProvider(session.id)).value ?? 0;
    final subtitle = connected
        ? l10n.remoteSwipeSwiped(swiped)
        : known.contains(peerFingerprint)
        ? l10n.remoteSwipePaused(device)
        : l10n.remoteSwipeOrphaned(device);
    return Card(
      child: ListTile(
        key: ValueKey('remote-swipe-${session.id}'),
        leading: const Icon(Icons.swipe_outlined),
        title: Text(l10n.remoteSwipeContinue(device)),
        subtitle: Text(subtitle),
        onTap: () =>
            unawaited(context.push(AppRoutes.connectSwipeFor(peerFingerprint))),
        trailing: IconButton(
          tooltip: l10n.remoteSwipeDiscard,
          icon: const Icon(Icons.delete_sweep_outlined),
          onPressed: () => unawaited(_discard(context, ref, device)),
        ),
      ),
    );
  }

  Future<void> _discard(
    BuildContext context,
    WidgetRef ref,
    String device,
  ) async {
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.remoteSwipeDiscardTitle(device)),
        content: Text(l10n.remoteSwipeDiscardBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.remoteSwipeDiscard),
          ),
        ],
      ),
    );
    if (ok != true) return;
    // Never calls the device: its files stay as they are.
    await ref.read(sessionRepositoryProvider).discard(session.id);
    ref.invalidate(swipeDeckForSourceProvider(session.sourceId));
  }
}
