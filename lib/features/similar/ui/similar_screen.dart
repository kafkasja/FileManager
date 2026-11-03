import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kfm/app/form_factor.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/router.dart';
import 'package:kfm/app/theme/app_tokens.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/thumbs/thumbnail.dart';
import 'package:kfm/desktop/compare/compare_view.dart';
import 'package:kfm/features/browse/ui/open_file.dart';
import 'package:kfm/features/session/data/session_providers.dart';
import 'package:kfm/features/similar/data/similar_repository.dart';
import 'package:kfm/features/similar/data/similar_scan_job.dart';
import 'package:kfm/features/similar/ui/similar_actions.dart';
import 'package:kfm/features/similar/ui/similar_providers.dart';

/// Similar and blurry photos (TASK-C2). Off until started; nothing is ever
/// removed unless the user chooses it.
class SimilarScreen extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<SimilarScreen> createState() => _SimilarScreenState();
}

class _SimilarScreenState extends ConsumerState<SimilarScreen> {
  @override
  void initState() {
    super.initState();
    unawaited(_dismissSwiped());
  }

  /// Groups fully swiped in swipe mode disappear (plan §7).
  Future<void> _dismissSwiped() async {
    try {
      final session = await ref.read(sessionRepositoryProvider).active();
      if (session == null) return;
      final undo = ref.read(undoRepositoryProvider);
      await undo.prepare(session.id);
      final acted = await undo.actedFileIds(session.id);
      await ref.read(similarRepositoryProvider).dismissFullySwiped(acted);
    } on Object {
      // Rule 8: the groups still show; nothing is lost by not hiding them.
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.browseLoadError)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final enabled = ref.watch(similarEnabledProvider).value;
    final groups = ref.watch(similarGroupsProvider).value ?? const [];
    if (enabled == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.similarTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (!enabled) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.similarTitle)),
        body: const _StartCard(),
      );
    }
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.similarTitle),
          actions: [
            if (groups.isNotEmpty)
              PopupMenuButton<_Menu>(
                onSelected: (m) => switch (m) {
                  _Menu.clean => unawaited(
                    context.push<void>(AppRoutes.similarClean),
                  ),
                  _Menu.swipeAll => unawaited(
                    swipeSimilar(context, ref, groups),
                  ),
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: _Menu.clean,
                    child: Text(l10n.similarCleanDuplicates),
                  ),
                  PopupMenuItem(
                    value: _Menu.swipeAll,
                    child: Text(l10n.similarSwipeAll),
                  ),
                ],
              ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.similarTabSimilar),
              Tab(text: l10n.similarTabBlurry),
            ],
          ),
        ),
        body: const Column(
          children: [
            _ProgressLine(),
            Expanded(child: TabBarView(children: [_GroupsTab(), _BlurryTab()])),
          ],
        ),
      ),
    );
  }
}

enum _Menu { clean, swipeAll }

class _StartCard extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final spacing = context.tokens.spacing;
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsetsDirectional.all(spacing * 3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.burst_mode_outlined,
              size: 56,
              color: Theme.of(context).colorScheme.primary,
            ),
            SizedBox(height: spacing * 2),
            Text(
              l10n.similarStartTitle,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: spacing),
            Text(l10n.similarStartBody, textAlign: TextAlign.center),
            SizedBox(height: spacing * 3),
            FilledButton(
              onPressed: () => unawaited(startSimilarScan(ref)),
              child: Text(l10n.similarStart),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressLine extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(similarScanProgressProvider).value;
    if (p == null || p.phase == SimilarScanPhase.idle) {
      return const SizedBox.shrink();
    }
    final l10n = context.l10n;
    final spacing = context.tokens.spacing;
    return Padding(
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: spacing * 2,
        vertical: spacing,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            p.phase == SimilarScanPhase.grouping
                ? l10n.similarGrouping
                : l10n.similarChecking(p.done, p.total),
          ),
          SizedBox(height: spacing / 2),
          LinearProgressIndicator(
            value: p.phase == SimilarScanPhase.grouping || p.total == 0
                ? null
                : p.done / p.total,
          ),
        ],
      ),
    );
  }
}

class _GroupsTab extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final groups = ref.watch(similarGroupsProvider);
    return switch (groups) {
      AsyncValue(:final value?) when value.isEmpty => _Empty(
        text: l10n.similarNoGroups,
      ),
      AsyncValue(:final value?) => ListView.builder(
        itemCount: value.length,
        itemBuilder: (context, i) => _GroupCard(group: value[i]),
      ),
      AsyncError() => _Empty(text: l10n.browseLoadError),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}

class _GroupCard extends ConsumerWidget {
  const new({required this.group});

  final SimilarGroup group;

  Future<void> _keepBest(BuildContext context, WidgetRef ref) async {
    final members = [for (final f in group.members) f.id];
    try {
      final op = await removeSimilar(
        context,
        ref,
        toRemove: group.members.sublist(1),
        members: members,
      );
      if (op != null && context.mounted) showSimilarOpSnack(context, ref, op);
    } on Object {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.swipeErrorGeneric)));
      }
    }
  }

  Future<void> _compare(BuildContext context, WidgetRef ref) async {
    final op = await showCompareView(context, members: group.members);
    if (op != null && context.mounted) showSimilarOpSnack(context, ref, op);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final spacing = context.tokens.spacing;
    return Card(
      margin: EdgeInsetsDirectional.symmetric(
        horizontal: spacing * 2,
        vertical: spacing,
      ),
      child: Padding(
        padding: EdgeInsetsDirectional.symmetric(vertical: spacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsetsDirectional.symmetric(horizontal: spacing * 2),
              child: Text(
                l10n.similarGroupCount(group.members.length),
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
            SizedBox(height: spacing),
            SizedBox(
              height: 104,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsetsDirectional.symmetric(horizontal: spacing),
                itemCount: group.members.length,
                separatorBuilder: (_, _) => SizedBox(width: spacing / 2),
                itemBuilder: (context, i) =>
                    _Thumb(file: group.members[i], best: i == 0),
              ),
            ),
            Wrap(
              spacing: spacing,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.auto_fix_high_outlined),
                  label: Text(l10n.similarKeepBest),
                  onPressed: () => unawaited(_keepBest(context, ref)),
                ),
                // PL3: the desktop app compares the group side by side.
                if (ref.watch(formFactorProvider).isDesktop)
                  TextButton.icon(
                    key: ValueKey('similar-compare-${group.id}'),
                    icon: const Icon(Icons.compare_outlined),
                    label: Text(l10n.desktopCompare),
                    onPressed: () => unawaited(_compare(context, ref)),
                  ),
                TextButton.icon(
                  icon: const Icon(Icons.swipe_outlined),
                  label: Text(l10n.similarSwipeGroup),
                  onPressed: () =>
                      unawaited(swipeSimilar(context, ref, [group])),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Thumb extends ConsumerWidget {
  const new({required this.file, this.best = false});

  final FileRef file;
  final bool best;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: best ? '${file.name}, ${context.l10n.similarBest}' : file.name,
      child: InkWell(
        onTap: () => unawaited(openFile(context, ref, file)),
        child: SizedBox.square(
          dimension: 104,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(context.tokens.radius / 2),
                child: Thumbnail(file: file),
              ),
              if (best)
                PositionedDirectional(
                  top: 4,
                  start: 4,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      child: Text(
                        context.l10n.similarBest,
                        style: TextStyle(color: scheme.onPrimary, fontSize: 12),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BlurryTab extends ConsumerStatefulWidget {
  const new();

  @override
  ConsumerState<_BlurryTab> createState() => _BlurryTabState();
}

class _BlurryTabState extends ConsumerState<_BlurryTab> {
  final Set<String> _picked = {};

  Future<void> _remove(List<FileRef> files) async {
    final chosen = [
      for (final f in files)
        if (_picked.contains(f.id)) f,
    ];
    if (chosen.isEmpty) return;
    try {
      final op = await removeSimilar(
        context,
        ref,
        toRemove: chosen,
        members: const [],
      );
      if (op == null || !mounted) return;
      setState(_picked.clear);
      showSimilarOpSnack(context, ref, op);
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.swipeErrorGeneric)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final blurry = ref.watch(similarBlurryProvider);
    final files = blurry.value ?? const <FileRef>[];
    // Files gone from the list (removed elsewhere) leave the selection.
    _picked.retainAll({for (final f in files) f.id});
    if (blurry.hasError) return _Empty(text: l10n.browseLoadError);
    if (!blurry.hasValue) {
      return const Center(child: CircularProgressIndicator());
    }
    if (files.isEmpty) return _Empty(text: l10n.similarNoBlurry);
    final spacing = context.tokens.spacing;
    return Column(
      children: [
        Expanded(
          child: GridView.builder(
            padding: EdgeInsets.all(spacing / 2),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 120,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            itemCount: files.length,
            itemBuilder: (context, i) {
              final f = files[i];
              final picked = _picked.contains(f.id);
              return Semantics(
                selected: picked,
                label: f.name,
                child: GestureDetector(
                  onTap: () => setState(
                    () => picked ? _picked.remove(f.id) : _picked.add(f.id),
                  ),
                  onLongPress: () => unawaited(openFile(context, ref, f)),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Thumbnail(file: f),
                      if (picked)
                        ColoredBox(
                          color: Theme.of(context).colorScheme.primary
                              .withValues(alpha: 0.35),
                          child: const Icon(
                            Icons.check_circle,
                            color: Colors.white,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.all(spacing),
            child: Row(
              children: [
                Expanded(child: Text(l10n.similarBlurryHint)),
                FilledButton(
                  onPressed: _picked.isEmpty
                      ? null
                      : () => unawaited(_remove(files)),
                  child: Text(l10n.similarRemoveCount(_picked.length)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Empty extends StatelessWidget {
  const new({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: EdgeInsetsDirectional.all(context.tokens.spacing * 3),
      child: Text(text, textAlign: TextAlign.center),
    ),
  );
}

/// Turns the finder on and starts the job.
Future<void> startSimilarScan(WidgetRef ref) async {
  await ref
      .read(settingsRepositoryProvider)
      .write(AppSettings.similarEnabled, true);
  kickSimilarScan(ref);
}
