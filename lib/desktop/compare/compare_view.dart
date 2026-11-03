import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/theme/app_tokens.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/utils/format.dart';
import 'package:kfm/desktop/widgets/desktop_keys.dart';
import 'package:kfm/desktop/widgets/file_explorer_parts.dart';
import 'package:kfm/features/similar/ui/similar_actions.dart';
import 'package:kfm/features/swipe/ui/media_view.dart';

/// Compare (TASK-PL3 step 6): the photos of one C2 similar / duplicate
/// group side by side, zoomed and panned together. The sharpest (the
/// group's first, C2's best pick) is marked Keep; the others will be
/// removed. Click a photo or press its number to switch Keep / Remove;
/// "Remove N" (Enter) runs C2's removal (deferred delete + Undo).
///
/// Returns C2's removal (for the caller's Undo snackbar), or null.
Future<SimilarOp?> showCompareView(
  BuildContext context, {
  required List<FileRef> members,
}) => showGeneralDialog<SimilarOp>(
  context: context,
  barrierDismissible: true,
  barrierLabel: context.l10n.desktopClose,
  barrierColor: Colors.black87,
  transitionDuration: const Duration(milliseconds: 120),
  pageBuilder: (context, _, _) => CompareView(members: members),
);

class CompareView extends ConsumerStatefulWidget {
  const new({required this.members, super.key});

  /// Best first (C2's order).
  final List<FileRef> members;

  /// Photos side by side at once; a strip below picks the others.
  static const maxShown = 4;

  @override
  ConsumerState<CompareView> createState() => _CompareViewState();
}

class _CompareViewState extends ConsumerState<CompareView> {
  final _zoom = TransformationController();
  final _focus = FocusNode(debugLabel: 'compare');
  late Set<String> _keep = {
    if (widget.members.isNotEmpty) widget.members.first.id,
  };

  /// First shown member (when the group has more than [CompareView.maxShown]).
  int _start = 0;
  bool _busy = false;

  @override
  void dispose() {
    _zoom.dispose();
    _focus.dispose();
    super.dispose();
  }

  List<FileRef> get _shown => widget.members
      .skip(_start)
      .take(CompareView.maxShown)
      .toList(growable: false);

  List<FileRef> get _toRemove => [
    for (final f in widget.members)
      if (!_keep.contains(f.id)) f,
  ];

  void _toggle(FileRef f) => setState(() {
    final next = {..._keep};
    if (!next.remove(f.id)) next.add(f.id);
    // At least one photo stays.
    if (next.isNotEmpty) _keep = next;
  });

  void _zoomBy(double factor) {
    final m = _zoom.value.clone();
    final scale = m.getMaxScaleOnAxis();
    final target = (scale * factor).clamp(1.0, 8.0);
    _zoom.value = Matrix4.diagonal3Values(target, target, 1)
      ..setTranslation(m.getTranslation() * (target / scale));
  }

  void _page(int delta) {
    final max = math.max(0, widget.members.length - CompareView.maxShown);
    setState(() => _start = (_start + delta).clamp(0, max));
  }

  Future<void> _remove() async {
    final remove = _toRemove;
    if (remove.isEmpty || _busy) return;
    setState(() => _busy = true);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final error = context.l10n.swipeErrorGeneric;
    try {
      final op = await removeSimilar(
        context,
        ref,
        toRemove: remove,
        members: [for (final f in widget.members) f.id],
      );
      if (!mounted) return;
      if (op == null) {
        setState(() => _busy = false);
        return;
      }
      navigator.pop(op);
    } on Object {
      if (mounted) setState(() => _busy = false);
      messenger.showSnackBar(SnackBar(content: Text(error)));
    }
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent e) {
    if (e is! KeyDownEvent && e is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = e.logicalKey;
    final digit = key.keyId - LogicalKeyboardKey.digit1.keyId;
    final pad = key.keyId - LogicalKeyboardKey.numpad1.keyId;
    final n = digit >= 0 && digit < 9
        ? digit
        : pad >= 0 && pad < 9
        ? pad
        : -1;
    final shown = _shown;
    if (n >= 0 && n < shown.length) {
      _toggle(shown[n]);
    } else if (key == LogicalKeyboardKey.equal ||
        key == LogicalKeyboardKey.numpadAdd) {
      _zoomBy(1.5);
    } else if (key == LogicalKeyboardKey.minus ||
        key == LogicalKeyboardKey.numpadSubtract) {
      _zoomBy(1 / 1.5);
    } else if (key == LogicalKeyboardKey.digit0 ||
        key == LogicalKeyboardKey.numpad0) {
      _zoom.value = Matrix4.identity();
    } else if (key == LogicalKeyboardKey.arrowRight) {
      _page(1);
    } else if (key == LogicalKeyboardKey.arrowLeft) {
      _page(-1);
    } else if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      unawaited(_remove());
    } else if (key == LogicalKeyboardKey.escape) {
      Navigator.of(context).pop();
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final shown = _shown;
    final remove = _toRemove.length;
    final locale = Localizations.localeOf(context).toLanguageTag();
    return Focus(
      focusNode: _focus,
      autofocus: true,
      onKeyEvent: _onKey,
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.desktopCompareTitle(widget.members.length),
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          l10n.desktopCompareHint,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    key: const ValueKey('compare-zoom-out'),
                    tooltip: shortcutHint(l10n, l10n.desktopZoomOut, '−'),
                    color: Colors.white,
                    icon: const Icon(Icons.zoom_out),
                    onPressed: () => _zoomBy(1 / 1.5),
                  ),
                  IconButton(
                    key: const ValueKey('compare-zoom-fit'),
                    tooltip: shortcutHint(l10n, l10n.desktopZoomFit, '0'),
                    color: Colors.white,
                    icon: const Icon(Icons.fit_screen_outlined),
                    onPressed: () => _zoom.value = Matrix4.identity(),
                  ),
                  IconButton(
                    key: const ValueKey('compare-zoom-in'),
                    tooltip: shortcutHint(l10n, l10n.desktopZoomIn, '+'),
                    color: Colors.white,
                    icon: const Icon(Icons.zoom_in),
                    onPressed: () => _zoomBy(1.5),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    key: const ValueKey('compare-remove'),
                    style: FilledButton.styleFrom(
                      backgroundColor: context.tokens.swipeTrash,
                    ),
                    onPressed: remove == 0 || _busy
                        ? null
                        : () => unawaited(_remove()),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: Text(
                      shortcutHint(
                        l10n,
                        l10n.desktopCompareRemove(remove),
                        'Enter',
                      ),
                    ),
                  ),
                  IconButton(
                    key: const ValueKey('compare-close'),
                    tooltip: shortcutHint(l10n, l10n.desktopClose, 'Esc'),
                    color: Colors.white,
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsetsDirectional.symmetric(horizontal: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final (i, f) in shown.indexed)
                      Expanded(
                        child: _Panel(
                          key: ValueKey('compare-panel-${f.id}'),
                          file: f,
                          number: i + 1,
                          best: f.id == widget.members.first.id,
                          keep: _keep.contains(f.id),
                          zoom: _zoom,
                          subtitle: l10n.desktopCompareFacts(
                            formatBytes(f.sizeBytes, locale: locale),
                            switch ((f.width, f.height)) {
                              (final w?, final h?) => '$w × $h',
                              _ => '—',
                            },
                            formatDateAndTime(f.sortDate, locale: locale),
                          ),
                          onToggle: () => _toggle(f),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (widget.members.length > CompareView.maxShown)
              SizedBox(
                height: 72,
                child: Row(
                  children: [
                    IconButton(
                      tooltip: shortcutHint(l10n, l10n.desktopPrevious, '←'),
                      color: Colors.white,
                      icon: const Icon(Icons.chevron_left),
                      onPressed: _start == 0 ? null : () => _page(-1),
                    ),
                    Expanded(
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          for (final (i, f) in widget.members.indexed)
                            Padding(
                              padding: const EdgeInsets.all(4),
                              child: InkWell(
                                onTap: () => _page(i - _start),
                                child: Opacity(
                                  opacity:
                                      i >= _start &&
                                          i < _start + CompareView.maxShown
                                      ? 1
                                      : 0.5,
                                  child: SizedBox.square(
                                    dimension: 64,
                                    child: FileTileBody(file: f),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: shortcutHint(l10n, l10n.desktopNext, '→'),
                      color: Colors.white,
                      icon: const Icon(Icons.chevron_right),
                      onPressed:
                          _start + CompareView.maxShown >= widget.members.length
                          ? null
                          : () => _page(1),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// One photo: zoomed with the others (one [TransformationController]),
/// its number key, Keep (green) or Remove (red).
class _Panel extends StatelessWidget {
  const new({
    required this.file,
    required this.number,
    required this.best,
    required this.keep,
    required this.zoom,
    required this.subtitle,
    required this.onToggle,
    super.key,
  });

  final FileRef file;
  final int number;
  final bool best;
  final bool keep;
  final TransformationController zoom;
  final String subtitle;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tokens = context.tokens;
    final theme = Theme.of(context);
    final color = keep ? tokens.swipeKeep : tokens.swipeTrash;
    return Padding(
      padding: const EdgeInsets.all(4),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color, width: 3),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(9),
          child: Column(
            children: [
              Expanded(
                child: InteractiveViewer(
                  transformationController: zoom,
                  minScale: 1,
                  maxScale: 8,
                  child: SizedBox.expand(child: MediaView(file: file)),
                ),
              ),
              Material(
                color: Colors.black54,
                child: InkWell(
                  key: ValueKey('compare-toggle-${file.id}'),
                  onTap: onToggle,
                  child: Padding(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    child: Row(
                      children: [
                        DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.white54),
                          ),
                          child: Padding(
                            padding: const EdgeInsetsDirectional.symmetric(
                              horizontal: 5,
                              vertical: 1,
                            ),
                            child: Text(
                              number.toString(),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                file.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (best)
                          Padding(
                            padding: const EdgeInsetsDirectional.only(end: 8),
                            child: Chip(
                              visualDensity: VisualDensity.compact,
                              label: Text(l10n.similarBest),
                            ),
                          ),
                        Icon(
                          keep ? Icons.check_circle : Icons.delete_outline,
                          color: color,
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          keep
                              ? l10n.desktopCompareKeep
                              : l10n.desktopCompareRemoveOne,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: color,
                          ),
                        ),
                      ],
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
