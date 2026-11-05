import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/app_info.dart';
import 'package:kfm/app/form_factor.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/features/session/data/session_providers.dart';
import 'package:kfm/l10n/generated/app_localizations.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'language_step.g.dart';

/// TASK-E2: whether the first-launch language question still has to be
/// asked. Existing installs (tutorial seen or anything swiped) are marked
/// asked silently, like L3's existing-install check. Null while loading.
@Riverpod(keepAlive: true)
class LanguageStepController extends _$LanguageStepController {
  @override
  Future<bool> build() async {
    final settings = ref.watch(settingsRepositoryProvider);
    if (await settings.read(AppSettings.onboardingLanguageAsked)) return false;
    final existing =
        await settings.read(AppSettings.onboardingTutorialDone) ||
        await ref.read(undoRepositoryProvider).hasAnyAction();
    if (existing) {
      await settings.write(AppSettings.onboardingLanguageAsked, true);
      return false;
    }
    return true;
  }

  /// Stores [tag] ('' = follow the system) and closes the step.
  Future<void> choose(String tag) async {
    state = const AsyncData(false);
    final settings = ref.read(settingsRepositoryProvider);
    await settings.write(AppSettings.localeTag, tag);
    await settings.write(AppSettings.onboardingLanguageAsked, true);
  }
}

/// Shows [child]; on the very first launch the language question covers
/// it first (phone: before the permission gate; desktop: a dialog-sized
/// card on the first shell frame; E3's icon choice waits for
/// `onboarding.languageAsked`).
class FirstLaunchLanguageGate extends ConsumerWidget {
  const new({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ask = ref.watch(languageStepControllerProvider).value ?? false;
    if (!ask) return child;
    final desktop = ref.watch(formFactorProvider).isDesktop;
    return Stack(
      children: [
        ExcludeSemantics(child: child),
        const ModalBarrier(dismissible: false, color: Colors.black54),
        Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: desktop ? 440 : 520),
            child: const Padding(
              padding: EdgeInsetsDirectional.all(16),
              child: Material(
                elevation: 6,
                borderRadius: BorderRadius.all(Radius.circular(24)),
                clipBehavior: Clip.antiAlias,
                child: LanguageStep(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// "System (English)", English, Nederlands, Türkçe, each in its own
/// language; preselected = the system language when KFM has it.
class LanguageStep extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<LanguageStep> createState() => _LanguageStepState();
}

class _LanguageStepState extends ConsumerState<LanguageStep> {
  String _choice = '';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // What "System" resolves to: KFM's language right now (the app follows
    // the system until a choice is stored).
    final system = Localizations.localeOf(context).toLanguageTag();
    final tags = [
      for (final l in AppLocalizations.supportedLocales) l.toLanguageTag(),
    ];
    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.fromSTEB(24, 24, 24, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.language, size: 40),
          const SizedBox(height: 12),
          Text(
            l10n.languageStepTitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          Text(
            l10n.languageStepBody,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          RadioGroup<String>(
            groupValue: _choice,
            onChanged: (v) => setState(() => _choice = v ?? ''),
            child: Column(
              children: [
                RadioListTile<String>(
                  key: const ValueKey('language-step-system'),
                  value: '',
                  title: Text(
                    l10n.languageSystemNamed(languageNames[system] ?? system),
                  ),
                ),
                for (final tag in tags)
                  RadioListTile<String>(
                    key: ValueKey('language-step-$tag'),
                    value: tag,
                    title: Text(languageNames[tag] ?? tag),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            key: const ValueKey('language-step-continue'),
            onPressed: () => unawaited(
              ref.read(languageStepControllerProvider.notifier).choose(_choice),
            ),
            child: Text(l10n.languageStepContinue),
          ),
        ],
      ),
    );
  }
}
