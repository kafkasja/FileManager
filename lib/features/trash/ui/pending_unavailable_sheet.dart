import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/theme/app_tokens.dart';
import 'package:kfm/features/trash/data/trash_providers.dart';
import 'package:kfm/features/trash/ui/pending_unavailable_list.dart';

/// H2: "Couldn't move to the pending-delete folder" (Options).
Future<void> showPendingUnavailableSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _Sheet(),
    );

class _Sheet extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(folderUnavailableProvider).value;
    if (items != null && items.isEmpty) {
      // Everything handled: close.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) Navigator.of(context).maybePop();
      });
    }
    final spacing = context.tokens.spacing;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: SingleChildScrollView(
          padding: EdgeInsetsDirectional.fromSTEB(
            spacing * 2,
            0,
            spacing * 2,
            spacing * 2,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.l10n.pendingUnavailableTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              SizedBox(height: spacing),
              PendingUnavailableList(items: items ?? const []),
            ],
          ),
        ),
      ),
    );
  }
}
