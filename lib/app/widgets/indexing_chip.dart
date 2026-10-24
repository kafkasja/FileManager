import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/theme/app_tokens.dart';
import 'package:kfm/core/index/index_providers.dart';
import 'package:kfm/core/index/media_indexer.dart';

/// "Indexing 12,345 files…" while the media index scans; "Indexing paused"
/// with a retry when it failed; hidden when idle.
class IndexingChip extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(indexStatusProvider).value;
    final l10n = context.l10n;
    final Widget chip;
    switch (status) {
      case IndexScanning(:final found):
        chip = Chip(
          avatar: const SizedBox.square(
            dimension: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          label: Text(l10n.indexingCount(found)),
        );
      case IndexFailed():
        chip = ActionChip(
          avatar: const Icon(Icons.pause_circle_outline),
          label: Text(l10n.indexingPaused),
          tooltip: l10n.retry,
          onPressed: () => ref.read(mediaIndexerProvider).start().ignore(),
        );
      case IndexIdle() || null:
        return const SizedBox.shrink();
    }
    return Padding(
      padding: EdgeInsetsDirectional.only(top: context.tokens.spacing),
      child: chip,
    );
  }
}
