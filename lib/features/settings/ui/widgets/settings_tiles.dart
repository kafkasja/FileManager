import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/layout/adaptive_list_tile.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/core/db/settings/setting_key.dart';
import 'package:kfm/l10n/generated/app_localizations.dart';

/// The common settings row (TASK-E2 §1): icon, title, the one-line
/// description and an optional trailing control (which moves under the
/// text at big sizes, [AdaptiveListTile]).
class SettingsTile extends StatelessWidget {
  const new({
    required this.title,
    this.subtitle,
    this.icon,
    this.trailing,
    this.onTap,
    this.chevron = false,
    super.key,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? trailing;
  final VoidCallback? onTap;

  /// Opens a screen: a chevron at the end.
  final bool chevron;

  @override
  Widget build(BuildContext context) {
    final end = trailing ?? (chevron ? const Icon(Icons.chevron_right) : null);
    return AdaptiveListTile(
      leading: icon == null ? null : Icon(icon),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: end,
      onTap: onTap,
    );
  }
}

/// A switch row with the same look as [SettingsTile].
class SettingsSwitchTile extends StatelessWidget {
  const new({
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.icon,
    super.key,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) => SwitchListTile(
    secondary: icon == null ? null : Icon(icon),
    title: Text(title),
    subtitle: subtitle == null ? null : Text(subtitle!),
    value: value,
    onChanged: onChanged,
  );
}

/// A switch over a bool setting: reads [provider], writes [setting].
class BoolSettingSwitch extends ConsumerWidget {
  const new({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.provider,
    required this.setting,
    this.afterWrite,
    super.key,
  });

  final IconData icon;
  final String Function(AppLocalizations l10n) title;
  final String Function(AppLocalizations l10n) subtitle;
  final ProviderListenable<AsyncValue<bool>> provider;
  final SettingKey<bool> setting;
  final void Function(WidgetRef ref)? afterWrite;

  @override
  Widget build(BuildContext context, WidgetRef ref) => SettingsSwitchTile(
    icon: icon,
    title: title(context.l10n),
    subtitle: subtitle(context.l10n),
    value: ref.watch(provider).value ?? setting.defaultValue,
    onChanged: (v) {
      final write = ref.read(settingsRepositoryProvider).write(setting, v);
      if (afterWrite case final after?) {
        write.then((_) => after(ref)).ignore();
      } else {
        write.fireAndForget();
      }
    },
  );
}
