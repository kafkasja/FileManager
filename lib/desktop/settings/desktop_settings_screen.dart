import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/form_factor.dart';
import 'package:kfm/features/settings/ui/settings_section.dart';
import 'package:kfm/features/settings/ui/settings_sections.dart';

/// Desktop Settings (TASK-PL3 step 5): the categories on the left, the
/// chosen one's content on the right. Built from the same
/// `settingsSectionsProvider` as the phone, without the phone-only
/// sections ([SettingsSection.formFactors]).
class DesktopSettingsScreen extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<DesktopSettingsScreen> createState() =>
      _DesktopSettingsScreenState();
}

class _DesktopSettingsScreenState extends ConsumerState<DesktopSettingsScreen> {
  /// [SettingsSection.order] of the open category.
  int? _open;

  @override
  Widget build(BuildContext context) {
    final sections = [
      for (final s in ref.watch(settingsSectionsProvider))
        if (s.formFactors.contains(FormFactor.desktop)) s,
    ];
    if (sections.isEmpty) return const SizedBox.shrink();
    final open = sections.firstWhere(
      (s) => s.order == _open,
      orElse: () => sections.first,
    );
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 240,
          child: ListView(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: 8,
              vertical: 8,
            ),
            children: [
              for (final s in sections)
                Padding(
                  padding: const EdgeInsetsDirectional.symmetric(vertical: 1),
                  child: ListTile(
                    key: ValueKey('settings-cat-${s.order}'),
                    dense: true,
                    selected: s == open,
                    selectedTileColor: colors.secondaryContainer,
                    selectedColor: colors.onSecondaryContainer,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    title: Text(
                      s.titleBuilder(context),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => setState(() => _open = s.order),
                  ),
                ),
            ],
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: Align(
            alignment: AlignmentDirectional.topStart,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: ListView(
                key: ValueKey('settings-pane-${open.order}'),
                padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 32),
                children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 8),
                    child: Text(
                      open.titleBuilder(context),
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  open.builder(context),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
