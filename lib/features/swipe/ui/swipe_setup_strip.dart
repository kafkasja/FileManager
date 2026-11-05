import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/theme/app_tokens.dart';
import 'package:kfm/features/connect/ui/known_device_names.dart';
import 'package:kfm/features/filters/domain/file_filter.dart';
import 'package:kfm/features/filters/ui/filter_sheet.dart';
import 'package:kfm/features/presets/data/preset_repository.dart';
import 'package:kfm/features/presets/domain/preset.dart';
import 'package:kfm/features/presets/ui/active_preset_controller.dart';
import 'package:kfm/features/presets/ui/preset_modified_provider.dart';
import 'package:kfm/features/session/domain/session_source.dart';
import 'package:kfm/features/swipe/domain/action_label.dart';
import 'package:kfm/features/swipe/domain/swipe_action.dart';
import 'package:kfm/features/swipe/domain/swipe_deck_state.dart';
import 'package:kfm/features/swipe/ui/swipe_setup_sheet.dart';
import 'package:kfm/features/swipe/ui/widgets/swipe_layout_editor.dart';
import 'package:kfm/features/tags/data/tag_providers.dart';

/// The strip's height: 48 dp, the Android tap target (E4; S6 had 40).
const double kSwipeSetupStripHeight = 48;

/// S6: the slim setup row under the app bar: active preset (tap = one-tap
/// preset row), what each direction does (tap = setup sheet), a filter
/// icon while a filter is on, and the tune icon (full sheet).
///
/// Remote decks (N8) show only the directions and the tune icon.
class SwipeSetupStrip extends ConsumerStatefulWidget {
  const new({
    required this.deck,
    this.sourceId = kLocalSourceId,
    this.deviceName = '',
    super.key,
  });

  final SwipeDeckState deck;
  final String sourceId;

  /// The other device's name for a remote deck.
  final String deviceName;

  @override
  ConsumerState<SwipeSetupStrip> createState() => _SwipeSetupStripState();
}

class _SwipeSetupStripState extends ConsumerState<SwipeSetupStrip> {
  /// S6-2 a: the preset chips replace the direction summary.
  bool _choosing = false;

  bool get _local => widget.sourceId == kLocalSourceId;

  void _openSheet(SwipeSetupSection section) => unawaited(
    showSwipeSetupSheet(
      context,
      sourceId: widget.sourceId,
      deviceName: widget.deviceName,
      initialSection: section,
    ),
  );

  Future<void> _switchTo(int? id) async {
    setState(() => _choosing = false);
    await ref.read(activePresetControllerProvider.notifier).switchTo(id);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final spacing = context.tokens.spacing;
    final scheme = Theme.of(context).colorScheme;
    final deck = widget.deck;
    final presets = _local
        ? ref.watch(presetsProvider).value ?? const <PresetEntry>[]
        : const <PresetEntry>[];
    if (_local) {
      // Moved here from P6's app-bar chip: a blocked switch says why.
      ref.listen(activePresetControllerProvider, (_, next) {
        final error = next.error;
        if (next.isLoading || error == null) return;
        final active = ref.read(activePresetEntryProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is PresetSwitchBlocked
                  ? l10n.presetSwitchBlocked(active?.name ?? l10n.presetBasic)
                  : l10n.swipeErrorGeneric,
            ),
          ),
        );
      });
    }
    final choosing = _choosing && presets.isNotEmpty;
    final filterOn =
        _local &&
        deck.source == null &&
        !FileFilter.decode(deck.session.filterJson).isEmpty;
    return Material(
      color: scheme.surfaceContainer,
      child: SizedBox(
        height: kSwipeSetupStripHeight,
        child: Row(
          children: [
            if (_local)
              _PresetPill(
                hasPresets: presets.isNotEmpty,
                open: choosing,
                onTap: presets.isEmpty
                    ? () => _openSheet(SwipeSetupSection.presets)
                    : () => setState(() => _choosing = !_choosing),
              )
            else
              SizedBox(width: spacing * 2),
            Expanded(
              child: choosing
                  ? _PresetRow(presets: presets, onPick: _switchTo)
                  : _DirectionSummary(
                      layout: deck.session.layout,
                      onTap: () => _openSheet(SwipeSetupSection.directions),
                    ),
            ),
            if (filterOn)
              IconButton(
                tooltip: l10n.swipeSetupFilterOn,
                onPressed: () => showFilterSheet(context),
                icon: const Badge(smallSize: 8, child: Icon(Icons.filter_list)),
              ),
            IconButton(
              tooltip: l10n.swipeSetupTuneTooltip,
              onPressed: () => _openSheet(SwipeSetupSection.presets),
              icon: const Icon(Icons.tune),
            ),
          ],
        ),
      ),
    );
  }
}

class _PresetPill extends ConsumerWidget {
  const new({
    required this.hasPresets,
    required this.open,
    required this.onTap,
  });

  final bool hasPresets;
  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final spacing = context.tokens.spacing;
    final scheme = Theme.of(context).colorScheme;
    final name = ref.watch(activePresetEntryProvider)?.name ?? l10n.presetBasic;
    final modified = ref.watch(presetModifiedProvider);
    final busy = ref.watch(activePresetControllerProvider).isLoading;
    return Semantics(
      button: true,
      label: modified
          ? l10n.swipeSetupPresetModifiedSemantics(name)
          : l10n.swipeSetupPresetSemantics(name),
      excludeSemantics: true,
      child: InkWell(
        onTap: busy ? null : onTap,
        child: Padding(
          padding: EdgeInsetsDirectional.only(start: spacing * 2, end: spacing),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 120),
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              if (modified)
                Padding(
                  padding: EdgeInsetsDirectional.only(start: spacing / 2),
                  child: Container(
                    key: const ValueKey('preset-modified-dot'),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: scheme.tertiary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              if (busy)
                Padding(
                  padding: EdgeInsetsDirectional.only(start: spacing / 2),
                  child: const SizedBox.square(
                    dimension: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else if (hasPresets)
                Icon(
                  open ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// S6-2 a: Basic + each preset; one tap switches.
class _PresetRow extends ConsumerWidget {
  const new({required this.presets, required this.onPick});

  final List<PresetEntry> presets;
  final Future<void> Function(int? id) onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final spacing = context.tokens.spacing;
    final activeId = ref.watch(activePresetIdProvider).value ?? 0;
    Widget chip(String name, int? id, {bool broken = false}) => Padding(
      padding: EdgeInsetsDirectional.only(end: spacing),
      child: ChoiceChip(
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        label: Text(broken ? l10n.swipeSetupPresetBroken : name),
        tooltip: broken ? name : null,
        selected: (id ?? 0) == activeId,
        onSelected: broken ? null : (_) => unawaited(onPick(id)),
      ),
    );
    return ListView(
      scrollDirection: Axis.horizontal,
      children: [
        chip(l10n.presetBasic, null),
        for (final p in presets)
          chip(p.name, p.id, broken: p is PresetLoadError),
      ],
    );
  }
}

/// "← Trash  → Keep  ↑ Move to Camera": assigned directions only, one
/// line, ellipsized.
class _DirectionSummary extends ConsumerWidget {
  const new({required this.layout, required this.onTap});

  final SwipeLayout layout;
  final VoidCallback onTap;

  static const List<SwipeDirection> _order = [
    SwipeDirection.left,
    SwipeDirection.right,
    SwipeDirection.up,
    SwipeDirection.down,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final spacing = context.tokens.spacing;
    final scheme = Theme.of(context).colorScheme;
    final tags = ref.watch(tagsByIdProvider).value ?? const {};
    final mode = ref.watch(swipeDeleteModeProvider);
    final style = Theme.of(context).textTheme.labelMedium;
    final spans = <InlineSpan>[];
    for (final d in _order) {
      final action = layout.actionFor(d);
      if (action == null) continue;
      final name = swipeActionName(
        l10n,
        action,
        mode,
        tags: tags,
        deviceNameOf: (id) => knownDeviceName(ref, id),
      );
      if (spans.isNotEmpty) {
        spans.add(WidgetSpan(child: SizedBox(width: spacing * 1.5)));
      }
      spans
        ..add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: ExcludeSemantics(
              child: Icon(
                swipeDirectionIcon(d),
                size: 14,
                color: scheme.primary,
              ),
            ),
          ),
        )
        ..add(
          TextSpan(
            text: ' $name',
            semanticsLabel: l10n.swipeSetupDirectionSemantics(
              swipeDirectionName(l10n, d),
              name,
            ),
          ),
        );
    }
    return InkWell(
      onTap: onTap,
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Padding(
          padding: EdgeInsetsDirectional.symmetric(horizontal: spacing),
          child: Text.rich(
            TextSpan(children: spans),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
        ),
      ),
    );
  }
}
