import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/router.dart';
import 'package:kfm/app/theme/app_tokens.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/core/utils/format.dart';
import 'package:kfm/features/presets/data/preset_repository.dart';
import 'package:kfm/features/stats/data/stats_repository.dart';
import 'package:kfm/features/stats/domain/stats_periods.dart';
import 'package:kfm/features/trash/data/trash_providers.dart';

/// Everything the screen shows, loaded at once.
@immutable
class _StatsView {
  const new({
    required this.inTrash,
    required this.week,
    required this.month,
    required this.allTime,
    required this.byPreset,
    required this.weekly,
  });

  final int inTrash;
  final StatsTotals week;
  final StatsTotals month;
  final StatsTotals allTime;
  final Map<int, StatsTotals> byPreset;
  final List<({DateTime weekStart, StatsTotals totals})> weekly;
}

final FutureProvider<_StatsView> _stats =
    FutureProvider.autoDispose<_StatsView>((ref) async {
      // Notice files that left the trash first (one listing).
      await ref.read(trashLedgerProvider).reconcileNow();
      final repo = ref.watch(statsRepositoryProvider);
      final raw = await ref
          .watch(settingsRepositoryProvider)
          .read(AppSettings.statsResetAt);
      final resetAt = raw.isEmpty ? null : DateTime.tryParse(raw)?.toLocal();
      final now = DateTime.now();
      final week = startOfWeek(now);
      return _StatsView(
        inTrash: await repo.inTrashBytes(),
        week: await repo.totals(from: laterOf(week, resetAt)),
        month: await repo.totals(from: laterOf(startOfMonth(now), resetAt)),
        allTime: await repo.totals(from: resetAt),
        byPreset: await repo.byPreset(from: resetAt),
        weekly: await repo.weekly(weekStart: week, notBefore: resetAt),
      );
    });

/// Settings → Swiping → Swipe stats (TASK-P8).
class StatsScreen extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toLanguageTag();
    String bytes(int b) => formatBytes(b < 0 ? 0 : b, locale: locale);
    final spacing = context.tokens.spacing;
    final stats = ref.watch(_stats);
    final presets = ref.watch(presetsProvider).value ?? const [];
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.statsTitle),
        actions: [
          PopupMenuButton<int>(
            onSelected: (_) => _reset(context, ref),
            itemBuilder: (_) => [
              PopupMenuItem(value: 0, child: Text(l10n.statsReset)),
            ],
          ),
        ],
      ),
      body: switch (stats) {
        AsyncData(:final value) => ListView(
          padding: EdgeInsetsDirectional.all(spacing * 2),
          children: [
            Text(
              l10n.statsInTrashFreed(
                bytes(value.inTrash),
                bytes(value.allTime.freedBytes),
              ),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(
                onPressed: () => context.go(AppRoutes.trash),
                child: Text(l10n.statsGoToTrash),
              ),
            ),
            for (final (label, t) in [
              (l10n.statsThisWeek, value.week),
              (l10n.statsThisMonth, value.month),
              (l10n.statsAllTime, value.allTime),
            ])
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(label),
                subtitle: Text(
                  l10n.statsRowLine(
                    l10n.statsReviewed(t.reviewed),
                    l10n.statsFreed(bytes(t.freedBytes)),
                  ),
                ),
              ),
            if (value.byPreset.isNotEmpty) ...[
              _Header(l10n.statsByPreset),
              for (final MapEntry(key: k, value: t) in _named(
                value.byPreset,
                {for (final p in presets) p.id: p.name},
                basic: l10n.presetBasic,
                deleted: l10n.statsDeletedPresets,
              ).entries)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(k),
                  subtitle: Text(
                    l10n.statsRowLine(
                      l10n.statsReviewed(t.reviewed),
                      l10n.statsFreed(bytes(t.freedBytes)),
                    ),
                  ),
                ),
            ],
            _Header(l10n.statsWeekly),
            for (final w in value.weekly)
              _WeekRow(
                label: MaterialLocalizations.of(context)
                    .formatShortMonthDay(w.weekStart),
                count: w.totals.reviewed,
                max: value.weekly.fold(
                  1,
                  (m, x) => x.totals.reviewed > m ? x.totals.reviewed : m,
                ),
              ),
          ],
        ),
        AsyncError(:final error) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(error.toString()),
              TextButton(
                onPressed: () => ref.invalidate(_stats),
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }

  /// Basic, presets by name, deleted presets summed.
  static Map<String, StatsTotals> _named(
    Map<int, StatsTotals> byKey,
    Map<int, String> names, {
    required String basic,
    required String deleted,
  }) {
    final out = <String, StatsTotals>{};
    void add(String name, StatsTotals t) {
      final prev = out[name] ?? StatsTotals.zero;
      out[name] = StatsTotals(
        reviewed: prev.reviewed + t.reviewed,
        freedBytes: prev.freedBytes + t.freedBytes,
      );
    }

    for (final MapEntry(key: k, value: t) in byKey.entries) {
      add(k == 0 ? basic : names[k] ?? deleted, t);
    }
    return out;
  }

  Future<void> _reset(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(l10n.statsResetConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.reset),
          ),
        ],
      ),
    );
    if (!(ok ?? false)) return;
    await ref
        .read(settingsRepositoryProvider)
        .write(
          AppSettings.statsResetAt,
          DateTime.now().toUtc().toIso8601String(),
        );
    ref.invalidate(_stats);
  }
}

class _Header extends StatelessWidget {
  const new(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.only(top: 16, bottom: 4),
    child: Text(
      text,
      style: Theme.of(context).textTheme.labelLarge
          ?.copyWith(color: Theme.of(context).colorScheme.primary),
    ),
  );
}

class _WeekRow extends StatelessWidget {
  const new({required this.label, required this.count, required this.max});

  final String label;
  final int count;
  final int max;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        SizedBox(width: 64, child: Text(label)),
        Expanded(
          child: LinearProgressIndicator(
            value: max == 0 ? 0 : count / max,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        SizedBox(
          width: 48,
          child: Text(count.toString(), textAlign: TextAlign.end),
        ),
      ],
    ),
  );
}
