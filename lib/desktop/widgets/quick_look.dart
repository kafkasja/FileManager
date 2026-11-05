import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/utils/format.dart';
import 'package:kfm/desktop/widgets/desktop_keys.dart';
import 'package:kfm/desktop/widgets/desktop_metrics.dart';
import 'package:kfm/features/swipe/ui/media_view.dart';
import 'package:kfm/features/swipe/ui/video_controller_pool.dart';

/// An action button (and key) inside Quick look.
@immutable
class QuickLookAction {
  const new({
    required this.label,
    required this.icon,
    required this.color,
    required this.run,
    this.keyHint,
    this.matches = _noKey,
    this.buttonKey,
    this.closes = false,
  });

  /// Quick look closes before [run] (it opens something underneath).
  final bool closes;

  final String label;
  final IconData icon;
  final Color color;

  /// The key shown on the button ("Del"); null = button only.
  final String? keyHint;
  final bool Function(KeyEvent event) matches;
  final Key? buttonKey;

  static bool _noKey(KeyEvent _) => false;

  /// Runs on `file`; true = it left the list (Quick look shows the next).
  final FutureOr<bool> Function(FileRef file) run;
}

/// Space / double-click (TASK-PL3): the photo or video big, ← → for the
/// previous/next file, the same action keys as the grid, Space or Esc to
/// close. [watchFiles] gives the current list (it shrinks as files are
/// sorted). Returns the file shown last (the grid focuses it).
Future<String?> showQuickLook(
  BuildContext context, {
  required List<FileRef> Function(WidgetRef ref) watchFiles,
  required String startId,
  List<QuickLookAction> actions = const [],
}) => showGeneralDialog<String>(
  context: context,
  barrierDismissible: true,
  barrierLabel: context.l10n.desktopClose,
  barrierColor: Colors.black87,
  transitionDuration: const Duration(milliseconds: 120),
  pageBuilder: (context, _, _) =>
      _QuickLook(watchFiles: watchFiles, startId: startId, actions: actions),
);

class _QuickLook extends ConsumerStatefulWidget {
  const new({
    required this.watchFiles,
    required this.startId,
    required this.actions,
  });

  final List<FileRef> Function(WidgetRef ref) watchFiles;
  final String startId;
  final List<QuickLookAction> actions;

  @override
  ConsumerState<_QuickLook> createState() => _QuickLookState();
}

class _QuickLookState extends ConsumerState<_QuickLook> {
  late String _id = widget.startId;
  int _index = 0;

  /// Files an action removed (Browse: deleted) that `watchFiles` may
  /// still list.
  final Set<String> _left = {};
  final _focus = FocusNode(debugLabel: 'quickLook');

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  void _close() => Navigator.of(context).pop(_id);

  void _step(List<FileRef> files, int delta) {
    if (files.isEmpty) return;
    final i = (_index + delta).clamp(0, files.length - 1);
    setState(() {
      _index = i;
      _id = files[i].id;
    });
  }

  void _run(QuickLookAction a, FileRef file) {
    if (a.closes) _close();
    unawaited(() async {
      final left = await a.run(file);
      if (left && mounted) setState(() => _left.add(file.id));
    }());
  }

  KeyEventResult _onKey(List<FileRef> files, FileRef? file, KeyEvent e) {
    if (e is! KeyDownEvent && e is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = e.logicalKey;
    // A video: Space plays / pauses it (Esc closes); otherwise Space closes.
    if (key == LogicalKeyboardKey.space && file?.kind == FileKind.video) {
      if (e is KeyDownEvent) {
        ref.read(videoPausedProvider.notifier).toggle(file!.id);
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.escape || key == LogicalKeyboardKey.space) {
      _close();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowRight) {
      _step(files, 1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowLeft) {
      _step(files, -1);
      return KeyEventResult.handled;
    }
    if (file != null) {
      for (final a in widget.actions) {
        if (a.matches(e)) {
          _run(a, file);
          return KeyEventResult.handled;
        }
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final files = [
      for (final f in widget.watchFiles(ref))
        if (!_left.contains(f.id)) f,
    ];
    // The shown file left the list (sorted): show the one now at its place.
    var i = files.indexWhere((f) => f.id == _id);
    if (i < 0 && files.isNotEmpty) {
      i = _index.clamp(0, files.length - 1);
      _id = files[i].id;
    }
    if (i >= 0) _index = i;
    final file = i >= 0 ? files[i] : null;
    if (file == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).maybePop(_id);
      });
    }
    final locale = Localizations.localeOf(context).toLanguageTag();
    const white = Colors.white;
    return Focus(
      focusNode: _focus,
      autofocus: true,
      onKeyEvent: (_, e) => _onKey(files, file, e),
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          children: [
            SizedBox(
              height: scaledExtent(context, 48),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  Expanded(
                    child: file == null
                        ? const SizedBox.shrink()
                        : Text(
                            l10n.desktopQuickLookTitle(
                              file.name,
                              formatBytes(file.sizeBytes, locale: locale),
                              formatDate(file.sortDate, locale: locale),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: white),
                          ),
                  ),
                  IconButton(
                    key: const ValueKey('quick-look-close'),
                    tooltip: shortcutHint(l10n, l10n.desktopClose, 'Esc'),
                    color: white,
                    icon: const Icon(Icons.close),
                    onPressed: _close,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  IconButton(
                    tooltip: shortcutHint(l10n, l10n.desktopPrevious, '←'),
                    color: white,
                    iconSize: 32,
                    icon: const Icon(Icons.chevron_left),
                    onPressed: _index > 0 ? () => _step(files, -1) : null,
                  ),
                  Expanded(
                    child: file == null
                        ? const SizedBox.shrink()
                        : MediaView(
                            key: ValueKey(file.id),
                            file: file,
                            desktopVideoControls: true,
                          ),
                  ),
                  IconButton(
                    tooltip: shortcutHint(l10n, l10n.desktopNext, '→'),
                    color: white,
                    iconSize: 32,
                    icon: const Icon(Icons.chevron_right),
                    onPressed: _index < files.length - 1
                        ? () => _step(files, 1)
                        : null,
                  ),
                ],
              ),
            ),
            if (widget.actions.isNotEmpty && file != null)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Wrap(
                  spacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    for (final a in widget.actions)
                      FilledButton.icon(
                        key: a.buttonKey,
                        style: FilledButton.styleFrom(
                          backgroundColor: a.color.withValues(alpha: 0.85),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => _run(a, file),
                        icon: Icon(a.icon, size: 18),
                        label: Text(
                          a.keyHint == null
                              ? a.label
                              : shortcutHint(l10n, a.label, a.keyHint!),
                        ),
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
