import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/features/browse/ui/same_time_controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'browse_settings_section.g.dart';

/// A size label on every photo/video tile in Browse.
@Riverpod(keepAlive: true)
Stream<bool> browseShowSizes(Ref ref) =>
    ref.watch(settingsRepositoryProvider).watch(AppSettings.browseShowSizes);

/// Big files (`FileGridTile.bigFileBytes`, 100 MB+) get a colored size
/// label.
@Riverpod(keepAlive: true)
Stream<bool> browseHighlightBig(Ref ref) =>
    ref.watch(settingsRepositoryProvider).watch(AppSettings.browseHighlightBig);

/// Settings → Browse.
class BrowseSettingsSection extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final settings = ref.read(settingsRepositoryProvider);
    final window = ref.watch(sameTimeWindowProvider).value ?? 5;
    return Column(
      children: [
        SwitchListTile(
          secondary: const Icon(Icons.straighten),
          title: Text(l10n.settingsShowSizes),
          subtitle: Text(l10n.settingsShowSizesHelp),
          value: ref.watch(browseShowSizesProvider).value ?? true,
          onChanged: (v) =>
              settings.write(AppSettings.browseShowSizes, v).fireAndForget(),
        ),
        SwitchListTile(
          secondary: const Icon(Icons.priority_high),
          title: Text(l10n.settingsHighlightBig),
          subtitle: Text(l10n.settingsHighlightBigHelp),
          value: ref.watch(browseHighlightBigProvider).value ?? false,
          onChanged: (v) =>
              settings.write(AppSettings.browseHighlightBig, v).fireAndForget(),
        ),
        ListTile(
          leading: const Icon(Icons.burst_mode_outlined),
          title: Text(l10n.settingsSameTimeWindow),
          subtitle: Text(l10n.settingsSameTimeWindowHelp),
          trailing: DropdownButton<int>(
            value: window,
            onChanged: (v) {
              if (v == null) return;
              settings
                  .write(AppSettings.sameTimeWindowSeconds, v)
                  .fireAndForget();
            },
            // A stored value outside the list (written elsewhere) is offered
            // too: the dropdown needs its value among the items.
            items: [
              for (final s in {..._windowChoices, window}.toList()..sort())
                DropdownMenuItem(value: s, child: Text(l10n.seconds(s))),
            ],
          ),
        ),
      ],
    );
  }

  /// B3: the "taken within" choices, in seconds.
  static const _windowChoices = [1, 2, 3, 5, 10, 30, 60, 120, 300, 600];
}
