import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/router.dart';
import 'package:kfm/app/theme/app_tokens.dart';
import 'package:kfm/features/connect/domain/link.dart';
import 'package:kfm/features/connect/ui/link_providers.dart';

/// Opens the linked device: its files when this device can browse them,
/// else the Connect screen (link details).
void openLinkedDevice(BuildContext context, DeviceLink link) {
  unawaited(
    context.push(
      link.iSeeTheirs
          ? AppRoutes.connectBrowseFor(link.peerFingerprint)
          : AppRoutes.connect,
    ),
  );
}

/// TASK-E1: "Connected to KAF-PC · Open", above the phone tabs (stacked
/// with X8's jobs bar) while a device is linked. Draws nothing otherwise.
class LinkChip extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final link = ref.watch(currentLinkProvider);
    if (link == null) return const SizedBox.shrink();
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final spacing = context.tokens.spacing;
    return Material(
      key: const ValueKey('link-chip'),
      color: theme.colorScheme.secondaryContainer,
      child: InkWell(
        onTap: () => openLinkedDevice(context, link),
        child: Padding(
          padding: EdgeInsetsDirectional.symmetric(
            horizontal: spacing * 2,
            vertical: spacing / 2,
          ),
          child: Row(
            children: [
              Icon(
                Icons.link,
                size: 18,
                color: theme.colorScheme.onSecondaryContainer,
              ),
              SizedBox(width: spacing),
              Expanded(
                child: Text(
                  l10n.linkConnectedTo(link.peerName),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
              TextButton(
                key: const ValueKey('link-chip-open'),
                onPressed: () => openLinkedDevice(context, link),
                child: Text(l10n.linkOpen),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// TASK-E1: the desktop status bar's "Connected to `phone`" (one line).
/// [onOpen] opens the device (desktop: a tab); default [openLinkedDevice].
class LinkStatusChip extends ConsumerWidget {
  const new({this.onOpen, super.key});

  final void Function(DeviceLink link)? onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final link = ref.watch(currentLinkProvider);
    if (link == null) return const SizedBox.shrink();
    final text = context.l10n.linkConnectedTo(link.peerName);
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 12),
      child: Semantics(
        button: true,
        label: text,
        excludeSemantics: true,
        child: InkWell(
          key: const ValueKey('link-status-chip'),
          onTap: () =>
              onOpen != null ? onOpen!(link) : openLinkedDevice(context, link),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.link,
                size: 14,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 4),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 220),
                child: Text(text, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
