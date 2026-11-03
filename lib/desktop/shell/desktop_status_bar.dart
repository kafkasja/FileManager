import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/router.dart';
import 'package:kfm/core/index/index_providers.dart';
import 'package:kfm/core/index/media_indexer.dart';
import 'package:kfm/core/utils/format.dart';
import 'package:kfm/desktop/shell/desktop_shell_state.dart';
import 'package:kfm/features/transfers/data/transfer_providers.dart';

/// Bottom status bar: items / selection of the current section on the
/// left, background work (indexing, transfers) on the right.
class DesktopStatusBar extends ConsumerWidget {
  const new({required this.section, super.key});

  final DesktopSection section;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final status = ref.watch(desktopStatusLineProvider(section));
    final locale = Localizations.localeOf(context).toLanguageTag();
    final index = ref.watch(indexStatusProvider).value;
    final transfers = ref.watch(runningTransferCountProvider);
    final style = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Container(
      height: 28,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 12),
      child: DefaultTextStyle.merge(
        style: style,
        child: Row(
          children: [
            if (status.items case final items?)
              Text(
                l10n.desktopStatusItems(items),
                key: const ValueKey('desktop-status-items'),
              ),
            if (status.selected > 0) ...[
              const SizedBox(width: 16),
              Text(
                l10n.desktopStatusSelected(
                  status.selected,
                  formatBytes(status.selectedBytes, locale: locale),
                ),
                key: const ValueKey('desktop-status-selected'),
              ),
            ],
            const Spacer(),
            if (index case IndexScanning(:final found)) ...[
              const SizedBox.square(
                dimension: 12,
                child: CircularProgressIndicator(strokeWidth: 1.5),
              ),
              const SizedBox(width: 6),
              Text(l10n.indexingCount(found)),
            ],
            if (index is IndexFailed)
              InkWell(
                onTap: () => ref.read(mediaIndexerProvider).start().ignore(),
                child: Text(l10n.indexingPaused),
              ),
            if (transfers > 0) ...[
              const SizedBox(width: 16),
              InkWell(
                onTap: () => context.push(AppRoutes.transfers),
                child: Row(
                  children: [
                    const Icon(Icons.swap_vert, size: 14),
                    const SizedBox(width: 4),
                    Text(l10n.transfersRunning(transfers)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
