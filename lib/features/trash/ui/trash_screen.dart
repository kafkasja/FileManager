import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/theme/app_tokens.dart';
import 'package:kfm/core/files/trash_types.dart';
import 'package:kfm/core/thumbs/thumbnail.dart';
import 'package:kfm/core/utils/format.dart';
import 'package:kfm/features/trash/data/trash_providers.dart';
import 'package:kfm/features/trash/ui/pending_unavailable_list.dart';
import 'package:kfm/features/trash/ui/trash_controller.dart';
import 'package:kfm/features/trash/ui/widgets/expiry_badge.dart';

/// Trash tab (TASK-D5): system trash and the pending folder on one page.
/// Tap or long-press selects (preview comes with S3).
class TrashScreen extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final trash = ref.watch(trashControllerProvider);
    final controller = ref.read(trashControllerProvider.notifier);
    final value = trash.value;
    final selecting = value?.selecting ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          selecting
              ? l10n.trashSelectedCount(value!.selectedIds.length)
              : l10n.tabTrash,
        ),
        leading: selecting
            ? IconButton(
                icon: const Icon(Icons.close),
                tooltip: l10n.cancel,
                onPressed: controller.clearSelection,
              )
            : null,
      ),
      body: switch (trash) {
        AsyncData(:final value) => RefreshIndicator(
          onRefresh: () => ref.refresh(trashControllerProvider.future),
          child: CustomScrollView(
            slivers: [
              const _UnavailableSection(),
              _Section(
                title: l10n.trashSystem,
                help: l10n.trashSystemHelp,
                items: value.system,
                state: value,
                media: true,
              ),
              _Section(
                title: l10n.trashPending,
                items: value.pending,
                state: value,
                media: false,
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 96)),
            ],
          ),
        ),
        AsyncError() => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.trashLoadFailed),
              TextButton(
                onPressed: () => ref.invalidate(trashControllerProvider),
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
      bottomNavigationBar: selecting
          ? _SelectionBar(busy: value!.busy, count: value.selectedIds.length)
          : null,
    );
  }
}

/// H2: deletes the pending folder couldn't take (any session).
class _UnavailableSection extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(folderUnavailableProvider).value ?? const [];
    if (items.isEmpty) return const SliverToBoxAdapter();
    final spacing = context.tokens.spacing;
    return SliverPadding(
      padding: EdgeInsetsDirectional.all(spacing * 2),
      sliver: SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.l10n.pendingUnavailableSection,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: spacing),
            PendingUnavailableList(items: items),
          ],
        ),
      ),
    );
  }
}

class _Section extends ConsumerWidget {
  const new({
    required this.title,
    required this.items,
    required this.state,
    required this.media,
    this.help,
  });

  final String title;
  final String? help;
  final List<TrashedItem> items;
  final TrashViewState state;

  /// Thumbnail grid (system trash) or list rows (pending folder).
  final bool media;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final spacing = context.tokens.spacing;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final bytes = items.fold<int>(0, (sum, i) => sum + i.original.sizeBytes);
    final controller = ref.read(trashControllerProvider.notifier);

    final header = ListTile(
      title: Text(title, style: Theme.of(context).textTheme.titleMedium),
      subtitle: Text(
        l10n.trashSectionSummary(
          items.length,
          formatBytes(bytes, locale: locale),
        ),
      ),
      trailing: items.isEmpty
          ? null
          : PopupMenuButton<String>(
              onSelected: (_) => _confirmDelete(context, ref, items),
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'empty',
                  child: Text(l10n.trashEmptySection),
                ),
              ],
            ),
    );

    Widget body;
    if (items.isEmpty) {
      body = SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsetsDirectional.all(spacing * 2),
          child: Text(l10n.trashNothingHere, textAlign: TextAlign.center),
        ),
      );
    } else if (media) {
      body = SliverPadding(
        padding: EdgeInsetsDirectional.symmetric(horizontal: spacing),
        sliver: SliverGrid.builder(
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 120,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
          ),
          itemCount: items.length,
          itemBuilder: (context, i) {
            final item = items[i];
            final selected = state.selectedIds.contains(item.trashId);
            return GestureDetector(
              onTap: () => controller.toggle(item.trashId),
              onLongPress: () => controller.toggle(item.trashId),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Thumbnail(file: item.original),
                  if (item.expiresAt != null)
                    PositionedDirectional(
                      start: 4,
                      bottom: 4,
                      child: ExpiryBadge(expiresAt: item.expiresAt!),
                    ),
                  if (selected) const _SelectedOverlay(),
                ],
              ),
            );
          },
        ),
      );
    } else {
      body = SliverList.builder(
        itemCount: items.length,
        itemBuilder: (context, i) {
          final item = items[i];
          final selected = state.selectedIds.contains(item.trashId);
          return ListTile(
            selected: selected,
            leading: SizedBox.square(
              dimension: 48,
              child: Thumbnail(file: item.original),
            ),
            title: Text(item.original.name),
            subtitle: Text(item.original.folderPath),
            trailing: item.expiresAt == null
                ? null
                : ExpiryBadge(expiresAt: item.expiresAt!),
            onTap: () => controller.toggle(item.trashId),
            onLongPress: () => controller.toggle(item.trashId),
          );
        },
      );
    }

    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(child: header),
        if (help != null && items.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsetsDirectional.fromSTEB(
                spacing * 2,
                0,
                spacing * 2,
                spacing,
              ),
              child: Text(help!, style: Theme.of(context).textTheme.bodySmall),
            ),
          ),
        body,
      ],
    );
  }
}

class _SelectedOverlay extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.35),
        border: Border.all(color: scheme.primary, width: 3),
      ),
      child: Align(
        alignment: AlignmentDirectional.topEnd,
        child: Padding(
          padding: const EdgeInsetsDirectional.all(4),
          child: Icon(Icons.check_circle, color: scheme.onPrimary),
        ),
      ),
    );
  }
}

class _SelectionBar extends ConsumerWidget {
  const new({required this.busy, required this.count});

  final bool busy;
  final int count;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final controller = ref.read(trashControllerProvider.notifier);
    return SafeArea(
      child: Padding(
        padding: EdgeInsetsDirectional.all(context.tokens.spacing),
        child: Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: busy
                    ? null
                    : () async {
                        final result = await controller.restoreSelected();
                        if (context.mounted) _report(context, result);
                      },
                icon: const Icon(Icons.restore),
                label: Text(l10n.trashRestore),
              ),
            ),
            SizedBox(width: context.tokens.spacing),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: busy
                    ? null
                    : () => _confirmDelete(
                        context,
                        ref,
                        ref.read(trashControllerProvider).value!.selected,
                      ),
                icon: const Icon(Icons.delete_forever_outlined),
                label: Text(l10n.trashDeleteForever),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _confirmDelete(
  BuildContext context,
  WidgetRef ref,
  List<TrashedItem> items,
) async {
  final l10n = context.l10n;
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.trashDeleteForeverTitle(items.length)),
      content: Text(l10n.trashDeleteForeverBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(l10n.trashDeleteForever),
        ),
      ],
    ),
  );
  if (ok != true) return;
  final result = await ref
      .read(trashControllerProvider.notifier)
      .deleteForever(items);
  if (context.mounted && result.cancelled) _report(context, result);
}

void _report(BuildContext context, TrashActionResult result) {
  final l10n = context.l10n;
  final text = result.cancelled && result.done == 0
      ? l10n.trashCancelled
      : result.alreadyGone > 0
      ? l10n.trashAlreadyRemoved
      : l10n.trashRestored(result.done);
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));
}
