import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/router.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/index/index_providers.dart';
import 'package:kfm/features/browse/ui/widgets/file_actions_menu.dart';
import 'package:kfm/features/connect/data/connect_providers.dart';
import 'package:kfm/features/connect/domain/link.dart';
import 'package:kfm/features/selection/ui/selection_actions.dart';
import 'package:kfm/features/transfers/data/transfer_providers.dart';

/// TASK-E1 "Send to `name`": one tap, no device picker. Through this
/// device's connection to the peer (an N12 offer into its receive folder)
/// or, when only the peer is connected here, an N12b inbox offer.
Future<void> sendToLink(
  BuildContext context,
  WidgetRef ref,
  DeviceLink link,
  List<FileRef> files,
) async {
  final local = [
    for (final f in files)
      if (f.origin != FileOrigin.remote) f,
  ];
  if (local.isEmpty) return;
  final l10n = context.l10n;
  final messenger = ScaffoldMessenger.maybeOf(context);
  final router = GoRouter.maybeOf(context);
  final name = link.peerName;
  try {
    if (link.connectedToThem) {
      await ref
          .read(transferEngineProvider)
          .enqueueSend(
            local,
            peerFingerprint: link.peerFingerprint,
            peerName: name,
          );
    } else {
      await ref
          .read(offerServiceProvider)
          .offerToClient(link.peerFingerprint, name, local);
    }
  } on Object {
    // X2 couldn't remove a location, or the queue failed (rule 8).
    messenger?.showSnackBar(
      SnackBar(persist: false, content: Text(l10n.linkSendFailed(name))),
    );
    return;
  }
  messenger
    ?..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        persist: false,
        content: Text(l10n.linkSending(local.length, name)),
        action: router == null
            ? null
            : SnackBarAction(
                label: l10n.transferShow,
                onPressed: () => router.push(AppRoutes.transfers),
              ),
      ),
    );
}

/// The ⋮ menu's first entry while linked (order 1: before Open with).
FileMenuItem sendToLinkFileMenuItem(DeviceLink link) => FileMenuItem(
  id: FileMenuIds.sendLinked,
  order: 1,
  label: (c) => c.l10n.linkSendTo(link.peerName),
  icon: Icons.send_to_mobile,
  isAvailable: (f) => f.origin != FileOrigin.remote,
  onSelected: (context, ref, f) => sendToLink(context, ref, link, [f]),
);

/// The selection bar's first button while linked.
SelectionAction sendToLinkSelectionAction(DeviceLink link) => SelectionAction(
  id: 'e1.sendLinked',
  primary: true,
  label: (c) => c.l10n.linkSendTo(link.peerName),
  icon: Icons.send_to_mobile,
  run: (context, ref, ids) async {
    final files = await ref.read(mediaIndexDaoProvider).byIds(ids);
    if (!context.mounted) return;
    await sendToLink(context, ref, link, files);
  },
);
