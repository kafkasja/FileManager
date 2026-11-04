import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kfm/app/adaptive_sheet.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/layout/adaptive_list_tile.dart';
import 'package:kfm/app/router.dart';
import 'package:kfm/app/theme/app_tokens.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/features/filters/domain/file_filter.dart';
import 'package:kfm/features/filters/ui/filter_sheet.dart';
import 'package:kfm/features/presets/data/preset_repository.dart';
import 'package:kfm/features/presets/domain/preset.dart';
import 'package:kfm/features/presets/ui/active_preset_controller.dart';
import 'package:kfm/features/presets/ui/preset_modified_provider.dart';
import 'package:kfm/features/presets/ui/save_preset_dialog.dart';
import 'package:kfm/features/session/domain/session_source.dart';
import 'package:kfm/features/swipe/ui/swipe_deck_controller.dart';
import 'package:kfm/features/swipe/ui/swipe_settings_section.dart';
import 'package:kfm/features/swipe/ui/widgets/swipe_layout_editor.dart';

/// Where [showSwipeSetupSheet] opens.
enum SwipeSetupSection { presets, directions, filter, extras }

/// S6: everything that shapes a swipe session in one sheet: presets (one
/// tap switches), directions, filter, extras and, when the session differs
/// from its preset, Save / Save as new / Revert. Changes apply to the
/// session at once, so the deck updates live behind the sheet.
///
/// A remote deck (N8) shows only directions and the global extras.
Future<void> showSwipeSetupSheet(
  BuildContext context, {
  String sourceId = kLocalSourceId,
  String deviceName = '',
  SwipeSetupSection initialSection = SwipeSetupSection.presets,
}) => showAdaptiveSheet<void>(
  context: context,
  isScrollControlled: true,
  maxDialogWidth: 640,
  builder: (_) => SwipeSetupSheet(
    sourceId: sourceId,
    deviceName: deviceName,
    initialSection: initialSection,
  ),
);

class SwipeSetupSheet extends ConsumerStatefulWidget {
  const new({
    this.sourceId = kLocalSourceId,
    this.deviceName = '',
    this.initialSection = SwipeSetupSection.presets,
    super.key,
  });

  final String sourceId;
  final String deviceName;
  final SwipeSetupSection initialSection;

  @override
  ConsumerState<SwipeSetupSheet> createState() => _SwipeSetupSheetState();
}

class _SwipeSetupSheetState extends ConsumerState<SwipeSetupSheet> {
  final Map<SwipeSetupSection, GlobalKey> _keys = {
    for (final s in SwipeSetupSection.values) s: GlobalKey(),
  };

  bool get _local => widget.sourceId == kLocalSourceId;

  @override
  void initState() {
    super.initState();
    if (widget.initialSection != SwipeSetupSection.presets) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final target = _keys[widget.initialSection]?.currentContext;
        if (target != null && target.mounted) {
          Scrollable.ensureVisible(
            target,
            duration: const Duration(milliseconds: 200),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final spacing = context.tokens.spacing;
    final deck = ref.watch(swipeDeckForSourceProvider(widget.sourceId)).value;
    final sourceOpen = deck?.source != null;
    Widget header(SwipeSetupSection section, String text) => Padding(
      key: _keys[section],
      padding: EdgeInsetsDirectional.only(top: spacing * 2, bottom: spacing),
      child: Text(text, style: Theme.of(context).textTheme.titleSmall),
    );
    return AdaptiveScrollSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      builder: (context, scroll, {required shrinkWrap}) => ListView(
        controller: scroll,
        shrinkWrap: shrinkWrap,
        padding: EdgeInsetsDirectional.fromSTEB(
          spacing * 2,
          0,
          spacing * 2,
          spacing * 3,
        ),
        children: [
          Text(
            _local
                ? l10n.swipeSetupTitle
                : l10n.swipeSetupRemoteTitle(widget.deviceName),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (_local) ...[
            header(SwipeSetupSection.presets, l10n.swipeSetupPresets),
            const _PresetsSection(),
          ],
          header(SwipeSetupSection.directions, l10n.swipeSetupDirections),
          SwipeLayoutEditor(sourceId: widget.sourceId, showActionBar: false),
          // SS1: the main filter is kept but hidden while a source is open.
          if (_local && !sourceOpen) ...[
            header(SwipeSetupSection.filter, l10n.swipeSetupFilter),
            _FilterSection(filterJson: deck?.session.filterJson),
          ],
          header(SwipeSetupSection.extras, l10n.swipeSetupExtras),
          _ExtrasSection(sourceId: widget.sourceId, showReviewed: !sourceOpen),
          if (_local) const _ModifiedFooter(),
        ],
      ),
    );
  }
}

class _PresetsSection extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final spacing = context.tokens.spacing;
    final presets = ref.watch(presetsProvider).value ?? const [];
    final activeId = ref.watch(activePresetIdProvider).value ?? 0;
    final busy = ref.watch(activePresetControllerProvider).isLoading;
    final controller = ref.read(activePresetControllerProvider.notifier);
    Widget chip(String name, int? id, {bool broken = false}) => ChoiceChip(
      label: Text(broken ? l10n.swipeSetupPresetBroken : name),
      tooltip: broken ? name : null,
      selected: (id ?? 0) == activeId,
      onSelected: busy || broken
          ? null
          : (_) => unawaited(controller.switchTo(id)),
    );
    Widget editable(PresetEntry p) => GestureDetector(
      // Long-press: the preset's editor (rename, setup, include reviewed).
      onLongPress: () {
        Navigator.of(context).pop();
        context.go(AppRoutes.presetEditorFor(p.id));
      },
      child: chip(p.name, p.id, broken: p is PresetLoadError),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: spacing,
          runSpacing: spacing,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            chip(l10n.presetBasic, null),
            for (final p in presets) editable(p),
            ActionChip(
              avatar: const Icon(Icons.bookmark_add_outlined, size: 18),
              label: Text(l10n.presetSaveAs),
              onPressed: () => unawaited(_saveAsNew(context, ref)),
            ),
            if (busy)
              const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
        if (presets.isNotEmpty)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              icon: const Icon(Icons.settings_outlined),
              label: Text(l10n.presetManage),
              onPressed: () {
                Navigator.of(context).pop();
                context.go(AppRoutes.presets);
              },
            ),
          ),
      ],
    );
  }
}

/// P6 "Save as preset…" from the current session; the session then belongs
/// to the new preset (X6 note: the chip shows its name at once).
Future<void> _saveAsNew(BuildContext context, WidgetRef ref) async {
  final messenger = ScaffoldMessenger.of(context);
  final l10n = context.l10n;
  final session = ref.read(swipeDeckControllerProvider).value?.session;
  if (session == null) return;
  final id = await showSavePresetDialog(
    context,
    layout: session.layout,
    filterJson: session.filterJson,
  );
  if (id == null) return;
  await ref.read(activePresetControllerProvider.notifier).adoptCurrentAs(id);
  final saved = await ref.read(presetRepositoryProvider).byId(id);
  if (saved != null) {
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.presetSaved(saved.name))),
    );
  }
}

class _FilterSection extends StatelessWidget {
  const new({required this.filterJson});

  final String? filterJson;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final on = !FileFilter.decode(filterJson).isEmpty;
    // The button moves under the text when the row is narrow (big text).
    return AdaptiveListTile(
      contentPadding: EdgeInsetsDirectional.zero,
      leading: Icon(on ? Icons.filter_alt : Icons.filter_list),
      title: Text(on ? l10n.presetEditorFilterOn : l10n.presetEditorFilterNone),
      trailing: TextButton(
        onPressed: () => showFilterSheet(context),
        child: Text(l10n.swipeSetupEditFilter),
      ),
      onTap: () => showFilterSheet(context),
    );
  }
}

class _ExtrasSection extends ConsumerWidget {
  const new({required this.sourceId, required this.showReviewed});

  final String sourceId;
  final bool showReviewed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final settings = ref.read(settingsRepositoryProvider);
    final local = sourceId == kLocalSourceId;
    final include = local && showReviewed
        ? ref.watch(swipeIncludesReviewedProvider)
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwipeActionBarEditor(sourceId: sourceId),
        SwitchListTile(
          contentPadding: EdgeInsetsDirectional.zero,
          title: Text(l10n.settingsSwipeButtons),
          subtitle: Text(l10n.settingsSwipeButtonsHelp),
          value: ref.watch(swipeButtonsModeProvider).value ?? false,
          onChanged: (v) =>
              settings.write(AppSettings.swipeButtonsMode, v).fireAndForget(),
        ),
        if (include != null)
          SwitchListTile(
            contentPadding: EdgeInsetsDirectional.zero,
            title: Text(l10n.reviewedIncludeToggle),
            value: include,
            onChanged: (v) => unawaited(ref.setSwipeIncludeReviewed(value: v)),
          ),
      ],
    );
  }
}

/// S6-3 a: the session differs from its preset → Save / Save as new /
/// Revert. With Basic active there is nothing to save into: only "Save as
/// preset…" (in the Presets row).
class _ModifiedFooter extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final spacing = context.tokens.spacing;
    final preset = ref.watch(activePresetEntryProvider);
    if (preset is! Preset || !ref.watch(presetModifiedProvider)) {
      return const SizedBox.shrink();
    }
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsetsDirectional.only(top: spacing * 2),
      child: Card(
        color: scheme.tertiaryContainer,
        child: Padding(
          padding: EdgeInsetsDirectional.all(spacing * 1.5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.swipeSetupModified(preset.name),
                style: TextStyle(color: scheme.onTertiaryContainer),
              ),
              SizedBox(height: spacing),
              Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  FilledButton(
                    onPressed: () => unawaited(_save(context, ref, preset)),
                    child: Text(l10n.swipeSetupSave),
                  ),
                  OutlinedButton(
                    onPressed: () => unawaited(_saveAsNew(context, ref)),
                    child: Text(l10n.swipeSetupSaveAsNew),
                  ),
                  TextButton(
                    onPressed: () => unawaited(ref.revertSessionToPreset()),
                    child: Text(l10n.swipeSetupRevert),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save(BuildContext context, WidgetRef ref, Preset preset) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    if (await ref.saveSessionToPreset()) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.swipeSetupSavedTo(preset.name))),
      );
    }
  }
}
