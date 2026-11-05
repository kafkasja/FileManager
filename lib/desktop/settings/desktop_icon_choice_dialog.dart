import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/form_factor.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/layout/adaptive_list_tile.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/desktop/widgets/file_type_icon.dart';
import 'package:kfm/features/settings/ui/settings_section.dart';


/// Settings → General → File icons (TASK-E3; desktop with the Windows
/// shell only).
final fileIconsEntry = SettingsEntry(
  id: 'general.fileIcons',
  titleBuilder: (c) => c.l10n.desktopFileIcons,
  subtitleBuilder: (c) => c.l10n.desktopFileIconsHint,
  formFactors: const {FormFactor.desktop},
  visible: (ref) => ref.watch(shellIconCacheProvider) != null,
  builder: (_) => const DesktopFileIconsRow(),
);

/// Settings → General: "File icons: Windows / KFM" (TASK-E3,
/// `general.fileIcons`, desktop with the Windows shell only).
class DesktopFileIconsRow extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(shellIconCacheProvider) == null) {
      return const SizedBox.shrink();
    }
    final l10n = context.l10n;
    final style =
        ref.watch(desktopIconStyleProvider).value ?? DesktopIconStyle.windows;
    return AdaptiveListTile(
      key: const ValueKey('general.fileIcons'),
      title: Text(l10n.desktopFileIcons),
      subtitle: Text(l10n.desktopFileIconsHint),
      trailing: DropdownButton<DesktopIconStyle>(
        value: style,
        onChanged: (s) {
          if (s == null) return;
          ref
              .read(settingsRepositoryProvider)
              .write(AppSettings.desktopIconStyle, s.name)
              .fireAndForget();
        },
        items: [
          DropdownMenuItem(
            value: DesktopIconStyle.windows,
            child: Text(l10n.desktopFileIconsWindows),
          ),
          DropdownMenuItem(
            value: DesktopIconStyle.kfm,
            child: Text(l10n.desktopFileIconsKfm),
          ),
        ],
      ),
    );
  }
}

/// Asks "Which file icons?" once on the desktop (first run, and existing
/// installs once since the change is visible), after E2's first-run
/// dialogs. Sits in the shell like the other prompters.
class DesktopIconChoicePrompter extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<DesktopIconChoicePrompter> createState() =>
      _DesktopIconChoicePrompterState();
}

class _DesktopIconChoicePrompterState
    extends ConsumerState<DesktopIconChoicePrompter> {
  var _started = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_maybeAsk()));
  }

  Future<void> _maybeAsk() async {
    if (_started || !mounted) return;
    _started = true;
    if (ref.read(shellIconCacheProvider) == null) return;
    final settings = ref.read(settingsRepositoryProvider);
    if (await settings.read(AppSettings.desktopIconsAsked)) return;
    // After E2's first-launch language dialog (`onboarding.languageAsked`).
    if (!await settings.read(AppSettings.onboardingLanguageAsked)) {
      await settings
          .watch(AppSettings.onboardingLanguageAsked)
          .firstWhere((asked) => asked);
    }
    if (!mounted) return;
    final current = DesktopIconStyle.parse(
      await settings.read(AppSettings.desktopIconStyle),
    );
    if (!mounted) return;
    final picked = await showDialog<DesktopIconStyle>(
      context: context,
      barrierDismissible: false,
      builder: (context) => DesktopIconChoiceDialog(initial: current),
    );
    await settings.write(AppSettings.desktopIconsAsked, true);
    if (picked != null) {
      await settings.write(AppSettings.desktopIconStyle, picked.name);
    }
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

/// Both icon styles side by side; returns the pick.
class DesktopIconChoiceDialog extends StatefulWidget {
  const new({required this.initial, super.key});

  final DesktopIconStyle initial;

  @override
  State<DesktopIconChoiceDialog> createState() =>
      _DesktopIconChoiceDialogState();
}

class _DesktopIconChoiceDialogState extends State<DesktopIconChoiceDialog> {
  late DesktopIconStyle _style = widget.initial;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    Widget option(DesktopIconStyle s, String title, String hint) => Expanded(
      child: _StyleCard(
        key: ValueKey('icon-choice-${s.name}'),
        style: s,
        title: title,
        hint: hint,
        selected: _style == s,
        onTap: () => setState(() => _style = s),
      ),
    );
    return AlertDialog(
      title: Text(l10n.desktopIconChoiceTitle),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.desktopIconChoiceBody),
            const SizedBox(height: 16),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  option(
                    DesktopIconStyle.windows,
                    l10n.desktopFileIconsWindows,
                    l10n.desktopIconChoiceWindowsHint,
                  ),
                  const SizedBox(width: 12),
                  option(
                    DesktopIconStyle.kfm,
                    l10n.desktopFileIconsKfm,
                    l10n.desktopIconChoiceKfmHint,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        FilledButton(
          key: const ValueKey('icon-choice-done'),
          onPressed: () => Navigator.of(context).pop(_style),
          child: Text(l10n.desktopIconChoiceDone),
        ),
      ],
    );
  }
}

class _StyleCard extends StatelessWidget {
  const new({
    required this.style,
    required this.title,
    required this.hint,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final DesktopIconStyle style;
  final String title;
  final String hint;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // The preview draws this style whatever the setting says now.
    final preview = Wrap(
      spacing: 8,
      children: [
        FileTypeIcon.folder('', size: 32, style: style),
        FileTypeIcon.path('a.pdf', size: 32, style: style),
        FileTypeIcon.path('a.zip', size: 32, style: style),
        FileTypeIcon.path('a.txt', size: 32, style: style),
      ],
    );
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsetsDirectional.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? scheme.primary : scheme.outlineVariant,
              width: selected ? 2 : 1,
            ),
            color: selected
                ? scheme.primaryContainer.withValues(alpha: 0.3)
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              preview,
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    size: 18,
                    color: selected ? scheme.primary : scheme.outline,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                hint,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
