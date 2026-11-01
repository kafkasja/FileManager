import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/theme/app_tokens.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/thumbs/thumbnail.dart';
import 'package:kfm/features/similar/data/similar_repository.dart';
import 'package:kfm/features/similar/ui/similar_actions.dart';
import 'package:kfm/features/similar/ui/similar_providers.dart';

/// Clean duplicates (TASK-C2): one group at a time, the best pre-marked
/// Keep; tap toggles Keep (several or all may be kept). "Next group"
/// removes the rest, "Skip" leaves the group, "Undo" reverts the last one.
class CleanDuplicatesScreen extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<CleanDuplicatesScreen> createState() =>
      _CleanDuplicatesScreenState();
}

class _CleanDuplicatesScreenState extends ConsumerState<CleanDuplicatesScreen> {
  /// Visible group ids when the screen opened, in order (regroups replace
  /// ids; a missing id is skipped).
  List<int>? _groupIds;
  int _index = 0;
  Set<String> _keep = {};
  int? _keepFor;
  SimilarOp? _lastOp;
  int? _lastIndex;
  bool _busy = false;

  SimilarGroup? _current(List<SimilarGroup> groups) {
    final ids = _groupIds;
    if (ids == null) return null;
    final byId = {for (final g in groups) g.id: g};
    while (_index < ids.length && !byId.containsKey(ids[_index])) {
      _index++;
    }
    return _index < ids.length ? byId[ids[_index]] : null;
  }

  Future<void> _next(SimilarGroup group) async {
    setState(() => _busy = true);
    final members = [for (final f in group.members) f.id];
    try {
      final op = await removeSimilar(
        context,
        ref,
        toRemove: [
          for (final f in group.members)
            if (!_keep.contains(f.id)) f,
        ],
        members: members,
      );
      if (!mounted) return;
      if (op == null) {
        setState(() => _busy = false);
        return;
      }
      setState(() {
        _lastOp = op;
        _lastIndex = _index;
        _index++;
        _busy = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.swipeErrorGeneric)));
    }
  }

  Future<void> _undo() async {
    final op = _lastOp;
    final index = _lastIndex;
    if (op == null || index == null) return;
    setState(() => _busy = true);
    try {
      await undoSimilar(ref, op);
      if (!mounted) return;
      setState(() {
        _index = index;
        _keepFor = null;
        _lastOp = null;
        _lastIndex = null;
        _busy = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.swipeErrorGeneric)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final spacing = context.tokens.spacing;
    final groups = ref.watch(similarGroupsProvider);
    final value = groups.value;
    if (value != null) _groupIds ??= [for (final g in value) g.id];
    final group = value == null ? null : _current(value);
    if (group != null && _keepFor != group.id) {
      _keepFor = group.id;
      _keep = {group.members.first.id};
    }
    final total = _groupIds?.length ?? 0;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.similarCleanDuplicates),
        actions: [
          if (_lastOp != null)
            TextButton(
              onPressed: _busy ? null : () => unawaited(_undo()),
              child: Text(l10n.undoAction),
            ),
        ],
      ),
      body: switch ((value, group)) {
        (null, _) when groups.hasError => Center(
          child: Text(l10n.browseLoadError),
        ),
        (null, _) => const Center(child: CircularProgressIndicator()),
        (_, null) => Center(
          child: Padding(
            padding: EdgeInsets.all(spacing * 3),
            child: Text(l10n.similarCleanDone, textAlign: TextAlign.center),
          ),
        ),
        (_, final SimilarGroup g) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.all(spacing * 2),
              child: Text(
                l10n.similarCleanProgress(
                  (_index + 1).clamp(1, total),
                  total,
                  _keep.length,
                ),
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: EdgeInsets.all(spacing),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 180,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemCount: g.members.length,
                itemBuilder: (context, i) => _KeepTile(
                  file: g.members[i],
                  best: i == 0,
                  keep: _keep.contains(g.members[i].id),
                  onTap: _busy
                      ? null
                      : () => setState(() {
                          final id = g.members[i].id;
                          _keep = {..._keep};
                          if (!_keep.remove(id)) _keep.add(id);
                        }),
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.all(spacing),
                child: Row(
                  children: [
                    TextButton(
                      onPressed: _busy ? null : () => setState(() => _index++),
                      child: Text(l10n.similarSkip),
                    ),
                    const Spacer(),
                    FilledButton(
                      onPressed: _busy ? null : () => unawaited(_next(g)),
                      child: Text(l10n.similarNextGroup),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      },
    );
  }
}

class _KeepTile extends StatelessWidget {
  const new({
    required this.file,
    required this.best,
    required this.keep,
    required this.onTap,
  });

  final FileRef file;
  final bool best;
  final bool keep;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: keep,
      label: keep ? l10n.similarKeep : l10n.similarRemove,
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Opacity(
                opacity: keep ? 1 : 0.45,
                child: Thumbnail(file: file),
              ),
            ),
            PositionedDirectional(
              bottom: 6,
              start: 6,
              end: 6,
              child: Row(
                children: [
                  _Chip(
                    text: keep ? l10n.similarKeep : l10n.similarRemove,
                    color: keep ? scheme.primary : scheme.error,
                    onColor: keep ? scheme.onPrimary : scheme.onError,
                  ),
                  const Spacer(),
                  if (best)
                    _Chip(
                      text: l10n.similarBest,
                      color: scheme.tertiary,
                      onColor: scheme.onTertiary,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const new({required this.text, required this.color, required this.onColor});

  final String text;
  final Color color;
  final Color onColor;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: 6,
        vertical: 2,
      ),
      child: Text(text, style: TextStyle(color: onColor, fontSize: 12)),
    ),
  );
}
