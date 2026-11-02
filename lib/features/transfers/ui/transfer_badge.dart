import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/router.dart';
import 'package:kfm/features/transfers/data/transfer_providers.dart';

/// App-bar action that opens the Transfers page (Connect screen, remote
/// browse); a badge counts queued and running jobs.
class TransfersAction extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(activeTransferCountProvider);
    return IconButton(
      key: const ValueKey('transfers-action'),
      tooltip: context.l10n.transfersTitle,
      onPressed: () => context.push(AppRoutes.transfers),
      icon: Badge(
        isLabelVisible: active > 0,
        label: Text(active.toString()),
        child: const Icon(Icons.swap_vert),
      ),
    );
  }
}

/// The swipe screen's chip, shown only while a transfer runs (never a
/// modal); tapping it opens the Transfers page.
class TransferBadge extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final running = ref.watch(runningTransferCountProvider);
    if (running == 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 4),
      child: ActionChip(
        key: const ValueKey('transfer-badge'),
        avatar: const Icon(Icons.swap_vert, size: 18),
        label: Text(running.toString()),
        tooltip: context.l10n.transfersRunning(running),
        onPressed: () => context.push(AppRoutes.transfers),
      ),
    );
  }
}
