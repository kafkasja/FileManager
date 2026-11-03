import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/theme/app_tokens.dart';
import 'package:kfm/features/onboarding/ui/onboarding_controller.dart';

/// A one-line hint shown once per [id] (TASK-L3). It counts as seen as soon
/// as it appears and stays until ✕ or until the screen goes away.
class FeatureHint extends ConsumerStatefulWidget {
  const new({required this.id, required this.text, super.key});

  final String id;
  final String text;

  @override
  ConsumerState<FeatureHint> createState() => _FeatureHintState();
}

class _FeatureHintState extends ConsumerState<FeatureHint> {
  /// null until the setting is known.
  bool? _showing;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingControllerProvider).value;
    if (_showing == null && state != null) {
      _showing = !state.seenHints.contains(widget.id);
      if (_showing!) {
        final notifier = ref.read(onboardingControllerProvider.notifier);
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => notifier.markHintSeen(widget.id),
        );
      }
    }
    if (_showing != true) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final spacing = context.tokens.spacing;
    return Material(
      color: scheme.secondaryContainer,
      child: Padding(
        padding: EdgeInsetsDirectional.only(start: spacing * 2),
        child: Row(
          children: [
            Icon(
              Icons.lightbulb_outline,
              size: 20,
              color: scheme.onSecondaryContainer,
            ),
            SizedBox(width: spacing),
            Expanded(
              child: Text(
                widget.text,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: scheme.onSecondaryContainer),
              ),
            ),
            IconButton(
              tooltip: context.l10n.hintDismiss,
              icon: const Icon(Icons.close),
              color: scheme.onSecondaryContainer,
              onPressed: () => setState(() => _showing = false),
            ),
          ],
        ),
      ),
    );
  }
}
