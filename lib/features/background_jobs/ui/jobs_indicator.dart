import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/router.dart';
import 'package:kfm/app/theme/app_tokens.dart';
import 'package:kfm/features/background_jobs/data/background_jobs_providers.dart';
import 'package:kfm/features/background_jobs/domain/job_notice.dart';
import 'package:kfm/features/background_jobs/domain/job_progress.dart';
import 'package:kfm/features/connect/data/connect_providers.dart';
import 'package:kfm/features/external_storage/data/places_repository.dart';
import 'package:kfm/features/external_storage/ui/place_labels.dart';

/// The notices' formatting in the widget tree's language.
NoticeFormat noticeFormatOf(BuildContext context, WidgetRef ref) {
  final l10n = context.l10n;
  final places = ref.watch(placesProvider).value ?? const [];
  return NoticeFormat(
    l10n: l10n,
    locale: Localizations.localeOf(context).toLanguageTag(),
    placeName: (t) {
      final p = places.where((p) => p.id == t.placeId).firstOrNull;
      return p == null ? t.folder : placeLabel(l10n, p);
    },
  );
}

/// What the indicator shows: the running jobs, else the paused ones.
({String title, double fraction, bool paused})? indicatorContent(
  JobsSnapshot s,
  NoticeFormat f,
) {
  final running = s.running;
  final shown = running.isNotEmpty ? running : s.paused;
  if (shown.isEmpty) return null;
  final fraction = JobsSnapshot.fractionOf(shown);
  final String title;
  if (running.isNotEmpty) {
    title = running.length == 1
        ? f.title(running.single)
        : f.l10n.jobsCombinedTitle(running.length, f.percent(fraction));
  } else {
    title = shown.length == 1
        ? f.l10n.jobsPausedOne(f.title(shown.single))
        : f.l10n.jobsPausedMany(shown.length);
  }
  return (title: title, fraction: fraction, paused: running.isEmpty);
}

/// TASK-X8: a slim progress bar shown on every tab while jobs run
/// (transfers, local copies, incoming uploads); a tap opens Transfers.
/// [compact]: one line for the desktop status bar.
class JobsIndicator extends ConsumerWidget {
  const new({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(currentJobsProvider);
    if (snapshot.isEmpty) return const SizedBox.shrink();
    final f = noticeFormatOf(context, ref);
    final content = indicatorContent(snapshot, f);
    if (content == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final spacing = context.tokens.spacing;
    final percent = f.percent(content.fraction);
    final icon = content.paused ? Icons.pause_circle_outline : Icons.swap_vert;
    void open() => context.push(AppRoutes.transfers);

    if (compact) {
      return Semantics(
        button: true,
        label: f.l10n.jobsIndicatorLabel(content.title, percent),
        excludeSemantics: true,
        child: InkWell(
          key: const ValueKey('jobs-indicator'),
          onTap: open,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14),
              const SizedBox(width: 4),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 280),
                child: Text(content.title, overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 80,
                child: LinearProgressIndicator(value: content.fraction),
              ),
              const SizedBox(width: 6),
              Text(percent),
            ],
          ),
        ),
      );
    }
    return Semantics(
      button: true,
      label: f.l10n.jobsIndicatorLabel(content.title, percent),
      excludeSemantics: true,
      child: Material(
        color: theme.colorScheme.surfaceContainerHigh,
        child: InkWell(
          key: const ValueKey('jobs-indicator'),
          onTap: open,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LinearProgressIndicator(
                value: content.fraction,
                minHeight: 2,
                color: content.paused ? theme.colorScheme.outline : null,
              ),
              Padding(
                padding: EdgeInsetsDirectional.symmetric(
                  horizontal: spacing * 2,
                  vertical: spacing,
                ),
                child: Row(
                  children: [
                    Icon(icon, size: 18, color: theme.colorScheme.primary),
                    SizedBox(width: spacing),
                    Expanded(
                      child: Text(
                        content.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                    SizedBox(width: spacing),
                    Text(percent, style: theme.textTheme.labelSmall),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// X8: on Android 13+ with notifications denied, jobs still run but show
/// their progress only in KFM (Transfers says so). Checked again when KFM
/// comes back (the user may have changed it).
class NotificationsOffNote extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<NotificationsOffNote> createState() =>
      _NotificationsOffNoteState();
}

class _NotificationsOffNoteState extends ConsumerState<NotificationsOffNote> {
  bool _allowed = true;
  AppLifecycleListener? _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _check);
    _check();
  }

  @override
  void dispose() {
    _lifecycle?.dispose();
    super.dispose();
  }

  void _check() {
    ref.read(shareBackgroundProvider).notificationsAllowed().then((allowed) {
      if (mounted && allowed != _allowed) setState(() => _allowed = allowed);
    }).ignore();
  }

  @override
  Widget build(BuildContext context) {
    if (_allowed) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final spacing = context.tokens.spacing;
    return Material(
      color: theme.colorScheme.secondaryContainer,
      child: Padding(
        padding: EdgeInsetsDirectional.all(spacing * 1.5),
        child: Row(
          children: [
            Icon(
              Icons.notifications_off_outlined,
              color: theme.colorScheme.onSecondaryContainer,
            ),
            SizedBox(width: spacing * 1.5),
            Expanded(
              child: Text(
                context.l10n.jobsNotificationsOff,
                key: const ValueKey('jobs-notifications-off'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSecondaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
