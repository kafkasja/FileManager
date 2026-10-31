import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/theme/app_tokens.dart';
import 'package:kfm/core/background/cancel_token.dart';
import 'package:kfm/core/utils/format.dart';
import 'package:kfm/features/folders/domain/file_operation.dart';

/// Batches with more files than this show the progress sheet; smaller ones
/// only get the end snackbar (TASK-B4 §5).
const progressSheetThreshold = 20;

/// Which "… {done} of {total}" line the sheet shows. [compressing] and
/// [extracting] (B5) count bytes ("Zipping 1.2 MB of 3 GB") and add an ETA.
enum ProgressLabel {
  moving,
  copying,
  deleting,
  undoing,
  working,
  compressing,
  extracting;

  bool get byBytes => this == compressing || this == extracting;
}

/// Shows [OperationProgressSheet] while [task] runs and closes it when the
/// task ends (also on an error, which is rethrown). [task] gets the
/// callback to report progress with (pass it as the runner's
/// `onProgress`). The sheet can't be dismissed; Cancel and the back button
/// call [cancel], the task then stops after the current file.
///
/// Dialogs the task opens meanwhile (collisions) show above the sheet.
Future<T> showOperationProgress<T>(
  BuildContext context, {
  required ProgressLabel label,
  required CancelToken cancel,
  required Future<T> Function(void Function(OperationProgress) onProgress) task,
}) async {
  final navigator = Navigator.of(context);
  // Not disposed: the sheet still listens during its exit animation.
  final progress = ValueNotifier<OperationProgress?>(null);
  final route = ModalBottomSheetRoute<void>(
    builder: (_) => OperationProgressSheet(
      progress: progress,
      cancel: cancel,
      label: label,
    ),
    capturedThemes: InheritedTheme.capture(
      from: context,
      to: navigator.context,
    ),
    barrierLabel: MaterialLocalizations.of(context).scrimLabel,
    isScrollControlled: false,
    isDismissible: false,
    enableDrag: false,
  );
  navigator.push(route);
  try {
    return await task((p) => progress.value = p);
  } finally {
    if (route.isActive) {
      if (route.isCurrent) {
        navigator.pop();
      } else {
        navigator.removeRoute(route);
      }
    }
  }
}

/// "Moving 12 of 500", a bar (by bytes when known), the current file
/// name, and Cancel.
/// Before the first event (or with `total == 0`, e.g. a folder rename) it
/// shows "Working…" and an indeterminate bar.
class OperationProgressSheet extends StatefulWidget {
  const new({
    required this.progress,
    required this.cancel,
    required this.label,
    super.key,
  });

  final ValueListenable<OperationProgress?> progress;
  final CancelToken cancel;
  final ProgressLabel label;

  @override
  State<OperationProgressSheet> createState() => _OperationProgressSheetState();
}

class _OperationProgressSheetState extends State<OperationProgressSheet> {
  late bool _cancelled = widget.cancel.isCancelled;

  /// Started at the first byte-based event, for the ETA.
  Stopwatch? _clock;

  void _cancel() {
    widget.cancel.cancel();
    setState(() => _cancelled = true);
  }

  String _line(OperationProgress? p) {
    final l10n = context.l10n;
    if (p == null || p.total == 0) return l10n.progressWorking;
    if (widget.label.byBytes) {
      final done = formatBytes(p.bytesDone, locale: l10n.localeName);
      final total = formatBytes(p.bytesTotal, locale: l10n.localeName);
      return widget.label == ProgressLabel.compressing
          ? l10n.progressCompressing(done, total)
          : l10n.progressExtracting(done, total);
    }
    // The file being worked on is number done + 1.
    final n = (p.done + 1).clamp(1, p.total);
    return switch (widget.label) {
      ProgressLabel.moving => l10n.progressMoving(n, p.total),
      ProgressLabel.copying => l10n.progressCopying(n, p.total),
      ProgressLabel.deleting => l10n.progressDeleting(n, p.total),
      ProgressLabel.undoing => l10n.progressUndoing(n, p.total),
      ProgressLabel.working ||
      ProgressLabel.compressing ||
      ProgressLabel.extracting => l10n.progressWorking,
    };
  }

  /// "About 3 minutes left" for byte-based labels, once a few percent are
  /// done (earlier estimates jump around).
  String? _eta(OperationProgress? p) {
    if (!widget.label.byBytes || p == null || p.bytesTotal <= 0) return null;
    if (p.bytesDone <= 0) return null;
    final clock = _clock ??= Stopwatch()..start();
    final elapsed = clock.elapsedMilliseconds;
    if (elapsed < 1000 || p.bytesDone < p.bytesTotal * 0.02) return null;
    final leftMs = elapsed * (p.bytesTotal - p.bytesDone) / p.bytesDone;
    return context.l10n.progressEtaMinutes((leftMs / 60000).ceil());
  }

  static double? _fraction(OperationProgress? p) {
    if (p == null || p.total == 0) return null;
    if (p.bytesTotal > 0) return (p.bytesDone / p.bytesTotal).clamp(0, 1);
    return (p.done / p.total).clamp(0, 1);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final spacing = context.tokens.spacing;
    final theme = Theme.of(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_cancelled) _cancel();
      },
      child: SafeArea(
        child: Padding(
          padding: EdgeInsetsDirectional.all(spacing * 3),
          child: ValueListenableBuilder<OperationProgress?>(
            valueListenable: widget.progress,
            builder: (context, p, _) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(_line(p), style: theme.textTheme.titleMedium),
                SizedBox(height: spacing * 2),
                LinearProgressIndicator(value: _fraction(p)),
                if (_eta(p) case final eta?) ...[
                  SizedBox(height: spacing),
                  Text(eta, style: theme.textTheme.bodySmall),
                ],
                if (p?.current case final current?) ...[
                  SizedBox(height: spacing),
                  Text(
                    current,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
                SizedBox(height: spacing * 2),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton(
                    onPressed: _cancelled ? null : _cancel,
                    child: Text(l10n.cancel),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
