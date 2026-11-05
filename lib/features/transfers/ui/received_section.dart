import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/file_reveal.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/theme/app_tokens.dart';
import 'package:kfm/core/utils/format.dart';
import 'package:kfm/features/connect/data/connect_providers.dart';
import 'package:kfm/features/connect/domain/share_offer.dart';
import 'package:kfm/features/connect/ui/incoming_offer_prompter.dart';
import 'package:kfm/l10n/generated/app_localizations.dart';

/// The Transfers page's "Received" tab (TASK-N12): one card per offer
/// this device's server holds. Incoming: "From S · N files · size" with
/// Waiting for you / "k of N received" + Stop / Done + Open folder.
/// Outgoing (N12b): "To R …" with its state and Stop.
class ReceivedOffersSection extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final spacing = context.tokens.spacing;
    final offers = ref.watch(shareOffersProvider).value ?? const <ShareOffer>[];
    if (offers.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsetsDirectional.all(spacing * 3),
          child: Text(l10n.transfersEmptyReceived, textAlign: TextAlign.center),
        ),
      );
    }
    return ListView.builder(
      padding: EdgeInsetsDirectional.all(spacing),
      itemCount: offers.length,
      itemBuilder: (context, i) => _OfferCard(offer: offers[i]),
    );
  }
}

String offerStatusText(AppLocalizations l10n, ShareOffer o) {
  final done = o.files.where((f) => f.status == OfferFileStatus.done).length;
  return switch (o.status) {
    OfferStatus.pending => l10n.transferWaitingForYou,
    OfferStatus.accepted when o.direction == OfferDirection.outgoing =>
      l10n.transferOfferAccepted,
    OfferStatus.accepted => l10n.transferOfferReceiving(done, o.fileCount),
    OfferStatus.done => l10n.transferOfferDone,
    OfferStatus.declined => l10n.transferOfferDeclined,
    OfferStatus.expired => l10n.transferOfferExpired,
    OfferStatus.cancelled || OfferStatus.failed => l10n.transferOfferCancelled,
  };
}

class _OfferCard extends ConsumerWidget {
  const new({required this.offer});

  final ShareOffer offer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final o = offer;
    final incoming = o.direction == OfferDirection.incoming;
    final size = formatBytes(o.totalBytes, locale: locale);
    final done = o.files.where((f) => f.status == OfferFileStatus.done).length;
    final folder = o.folder;
    return Card(
      key: ValueKey('offer-card-${o.id}'),
      child: ListTile(
        leading: Icon(
          incoming ? Icons.move_to_inbox_outlined : Icons.outbox_outlined,
        ),
        title: Text(
          incoming
              ? l10n.transferFromDeviceOffer(o.peerName, o.fileCount, size)
              : l10n.transferToDeviceOffer(o.peerName, o.fileCount, size),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(offerStatusText(l10n, o)),
            if (incoming && o.status == OfferStatus.accepted)
              Padding(
                padding: EdgeInsetsDirectional.only(
                  top: context.tokens.spacing / 2,
                ),
                child: LinearProgressIndicator(
                  value: o.fileCount == 0 ? 0 : done / o.fileCount,
                ),
              ),
            Wrap(
              spacing: context.tokens.spacing,
              children: [
                if (o.isOpen)
                  TextButton(
                    key: ValueKey('offer-stop-${o.id}'),
                    onPressed: () => unawaited(
                      ref.read(offerServiceProvider).stopByReceiver(o.id),
                    ),
                    child: Text(l10n.transferOfferStop),
                  ),
                if (incoming && folder != null && done > 0) ...[
                  TextButton(
                    key: ValueKey('offer-open-${o.id}'),
                    onPressed: () =>
                        unawaited(openReceivedFolder(context, ref, folder)),
                    child: Text(l10n.transferOfferOpenFolder),
                  ),
                  // E1: Show in folder / Open / Copy path (one file: that
                  // file; several: the folder).
                  ReceivedFileMenu(
                    key: ValueKey('offer-menu-${o.id}'),
                    folder: folder,
                    path: () => done == 1
                        ? localPathOfReceived(
                            ref,
                            o.files
                                .firstWhere(
                                  (f) => f.status == OfferFileStatus.done,
                                )
                                .localFileId,
                          )
                        : Future.value(),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
