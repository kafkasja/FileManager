import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/theme/app_tokens.dart';
import 'package:kfm/features/settings/ui/settings_sections.dart';

/// Built from `settingsSectionsProvider`; never add rows here directly.
class SettingsScreen extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sections = ref.watch(settingsSectionsProvider);
    final spacing = context.tokens.spacing;
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.settingsTitle)),
      body: ListView(
        padding: EdgeInsetsDirectional.only(bottom: spacing * 2),
        children: [
          for (final section in sections) ...[
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(
                spacing * 2,
                spacing * 3,
                spacing * 2,
                spacing,
              ),
              child: Text(
                section.titleBuilder(context),
                style: Theme.of(context).textTheme.titleSmall
                    ?.copyWith(color: Theme.of(context).colorScheme.primary),
              ),
            ),
            section.builder(context),
          ],
        ],
      ),
    );
  }
}
