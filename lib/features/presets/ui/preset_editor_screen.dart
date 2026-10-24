import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/theme/app_tokens.dart';
import 'package:kfm/features/filters/domain/file_filter.dart';
import 'package:kfm/features/filters/ui/filter_sheet.dart';
import 'package:kfm/features/presets/data/preset_repository.dart';
import 'package:kfm/features/presets/domain/preset.dart';
import 'package:kfm/features/session/data/session_providers.dart';
import 'package:kfm/features/swipe/domain/swipe_action.dart';
import 'package:kfm/features/swipe/ui/customize_swipes_screen.dart';
import 'package:kfm/features/swipe/ui/swipe_deck_controller.dart';
import 'package:kfm/features/swipe/ui/swipe_layout_controller.dart';
import 'package:kfm/features/tags/data/tag_providers.dart';
import 'package:kfm/features/trash/data/trash_providers.dart';
import 'package:kfm/features/trash/domain/delete_mode.dart';

/// The only place a preset's saved setup changes (TASK-P6): name, swipe
/// buttons, action bar, filter. Save also updates the preset's open
/// session; Back with changes asks first.
class PresetEditorScreen extends ConsumerStatefulWidget {
  const new({required this.presetId, super.key});

  final int presetId;

  @override
  ConsumerState<PresetEditorScreen> createState() => _PresetEditorState();
}

class _PresetEditorState extends ConsumerState<PresetEditorScreen> {
  final _name = TextEditingController();
  String _savedName = '';
  SwipeLayout _layout = SwipeLayout.basic;
  SwipeLayout _savedLayout = SwipeLayout.basic;
  String? _filterJson;
  String? _savedFilterJson;
  bool _loaded = false;
  bool _hasOpenSession = false;
  String? _nameError;

  bool get _dirty =>
      _name.text.trim() != _savedName ||
      _layout != _savedLayout ||
      _filterJson != _savedFilterJson;

  @override
  void initState() {
    super.initState();
    _load().ignore();
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final entry = await ref
        .read(presetRepositoryProvider)
        .byId(widget.presetId);
    final sessions = ref.read(sessionRepositoryProvider);
    final active = await sessions.active();
    final open =
        active?.presetId == widget.presetId ||
        await sessions.pausedFor(widget.presetId) != null;
    if (!mounted || entry == null) return;
    setState(() {
      _savedName = entry.name;
      _name.text = entry.name;
      // A broken row opens as Basic with no filter; Save repairs it.
      if (entry case Preset(:final layout, :final filterJson)) {
        _layout = _savedLayout = layout;
        _filterJson = _savedFilterJson = filterJson;
      }
      _hasOpenSession = open;
      _loaded = true;
    });
  }

  Future<void> _pickDirection(SwipeDirection d) async {
    final current = _layout.actionFor(d);
    final picked = await pickSwipeAction(
      context,
      title: swipeDirectionName(context.l10n, d),
      current: current,
      canPickNothing: !(current != null && _layout.directions.length == 1),
    );
    if (picked == null) return;
    setState(() => _layout = _layout.withDirection(d, picked.action));
  }

  Future<void> _addBarAction() async {
    final action = (await pickSwipeAction(
      context,
      title: context.l10n.actionBarAdd,
      showNothing: false,
      disabledTypes: barTypesInUse(_layout),
    ))?.action;
    if (action == null || _layout.actionBar.contains(action)) return;
    setState(
      () => _layout = _layout.withActionBar([..._layout.actionBar, action]),
    );
  }

  Future<void> _editFilter() => showFilterSheet(
    context,
    initial: FileFilter.decode(_filterJson),
    onSave: (f) =>
        setState(() => _filterJson = f.isEmpty ? null : jsonEncode(f.toJson())),
  );

  Future<void> _save() async {
    final l10n = context.l10n;
    final repo = ref.read(presetRepositoryProvider);
    final navigator = Navigator.of(context);
    try {
      if (_name.text.trim() != _savedName) {
        await repo.rename(widget.presetId, _name.text);
      }
    } on PresetNameException catch (e) {
      setState(
        () => _nameError = e.problem == PresetNameProblem.taken
            ? l10n.presetNameTaken
            : l10n.presetNameInvalid,
      );
      return;
    }
    await repo.updateSetup(
      widget.presetId,
      layout: _layout,
      filterJson: _filterJson,
    );
    await ref
        .read(sessionRepositoryProvider)
        .applyPresetToOpenSession(
          widget.presetId,
          layout: _layout,
          filterJson: _filterJson,
        );
    if (await ref.read(activePresetIdProvider.future) == widget.presetId) {
      ref
        ..invalidate(swipeDeckControllerProvider)
        ..invalidate(swipeLayoutControllerProvider);
    }
    setState(() {
      _savedName = _name.text.trim();
      _savedLayout = _layout;
      _savedFilterJson = _filterJson;
    });
    navigator.pop();
  }

  Future<bool> _confirmDiscard() async {
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.presetEditorDiscard),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.presetDiscard),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final spacing = context.tokens.spacing;
    final tags = ref.watch(tagsByIdProvider).value ?? const {};
    final mode = ref.watch(deleteModeSettingProvider).value ?? DeleteMode.trash;
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        if (await _confirmDiscard()) {
          setState(() {
            _name.text = _savedName;
            _layout = _savedLayout;
            _filterJson = _savedFilterJson;
          });
          navigator.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.presetEditorTitle),
          actions: [
            // Always reachable (the list can be longer than the screen).
            TextButton(
              onPressed: _dirty ? _save : null,
              child: Text(l10n.presetEditorSave),
            ),
          ],
        ),
        body: !_loaded
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: EdgeInsetsDirectional.all(spacing * 2),
                children: [
                  TextField(
                    controller: _name,
                    maxLength: kPresetNameMax,
                    onChanged: (_) => setState(() => _nameError = null),
                    decoration: InputDecoration(
                      labelText: l10n.presetNameLabel,
                      errorText: _nameError,
                    ),
                  ),
                  _Header(l10n.presetDirections),
                  for (final d in const [
                    SwipeDirection.left,
                    SwipeDirection.right,
                    SwipeDirection.up,
                    SwipeDirection.down,
                  ])
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(swipeDirectionName(l10n, d)),
                      subtitle: Text(
                        swipeActionName(
                          l10n,
                          _layout.actionFor(d),
                          mode,
                          tags: tags,
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _pickDirection(d),
                    ),
                  _Header(l10n.actionBarTitle),
                  for (final (i, a) in _layout.actionBar.indexed)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(swipeActionName(l10n, a, mode, tags: tags)),
                      trailing: IconButton(
                        tooltip: l10n.actionBarRemove,
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () => setState(
                          () => _layout = _layout.withActionBar([
                            for (final (j, b) in _layout.actionBar.indexed)
                              if (j != i) b,
                          ]),
                        ),
                      ),
                    ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.add),
                    title: Text(l10n.actionBarAdd),
                    enabled:
                        _layout.actionBar.length <
                        SwipeLayoutController.maxBarActions,
                    onTap: _addBarAction,
                  ),
                  _Header(l10n.presetFilter),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.filter_list),
                    title: Text(
                      _filterJson == null
                          ? l10n.presetEditorFilterNone
                          : l10n.presetEditorFilterOn,
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _editFilter,
                  ),
                  SizedBox(height: spacing * 2),
                  if (_hasOpenSession)
                    Padding(
                      padding: EdgeInsetsDirectional.only(top: spacing),
                      child: Text(
                        l10n.presetEditorReplacesSession,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                ],
              ),
      ),
    );
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
