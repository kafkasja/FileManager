import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/form_factor.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/features/settings/ui/settings_entry_view.dart';
import 'package:kfm/features/settings/ui/settings_search.dart';
import 'package:kfm/features/settings/ui/settings_section.dart';
import 'package:kfm/features/settings/ui/settings_sections.dart';

/// Desktop Settings (TASK-PL3 step 5, E2): a search field and the categories
/// on the left, the chosen one's entries on the right. Built from the same
/// `settingsSectionsProvider` as the phone, with only the desktop entries
/// ([SettingsEntry.formFactors]). Ctrl+F focuses the search; [entry] (the
/// `/settings?entry=<id>` deep link) opens that entry's category, scrolls to
/// it and flashes it.
class DesktopSettingsScreen extends ConsumerStatefulWidget {
  const new({this.entry, super.key});

  final String? entry;

  @override
  ConsumerState<DesktopSettingsScreen> createState() =>
      _DesktopSettingsScreenState();
}

class _DesktopSettingsScreenState extends ConsumerState<DesktopSettingsScreen> {
  static const FormFactor _formFactor = FormFactor.desktop;

  /// [SettingsSection.id] of the open category.
  String? _open;
  final _jump = SettingsJumpController();
  final _query = TextEditingController();
  final _searchFocus = FocusNode(debugLabel: 'settings-search');

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKey);
    if (widget.entry case final id?) _jumpTo(id, rebuild: false);
  }

  /// Ctrl+F focuses the search while Settings is the shown section (the
  /// other shell branches stay mounted with tickers off).
  bool _onKey(KeyEvent e) {
    if (e is! KeyDownEvent ||
        e.logicalKey != LogicalKeyboardKey.keyF ||
        !HardwareKeyboard.instance.isControlPressed ||
        !mounted ||
        !TickerMode.valuesOf(context).enabled) {
      return false;
    }
    _searchFocus.requestFocus();
    return true;
  }

  @override
  void didUpdateWidget(DesktopSettingsScreen old) {
    super.didUpdateWidget(old);
    if (widget.entry case final id? when id != old.entry) _jumpTo(id);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    _jump.dispose();
    _query.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _jumpTo(String id, {bool rebuild = true}) {
    final section = sectionOfEntry(ref.read(settingsSectionsProvider), id);
    if (section == null) return;
    void apply() {
      _open = section.id;
      _query.clear();
    }

    rebuild ? setState(apply) : apply();
    _jump.jumpTo(id);
  }

  @override
  Widget build(BuildContext context) {
    final shown = <(SettingsSection, List<SettingsEntry>)>[
      for (final s in ref.watch(settingsSectionsProvider))
        if (visibleEntries(ref, s, _formFactor) case final entries
            when entries.isNotEmpty)
          (s, entries),
    ];
    if (shown.isEmpty) return const SizedBox.shrink();
    final open = shown.firstWhere(
      (s) => s.$1.id == _open,
      orElse: () => shown.first,
    );
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final query = _query.text.trim();
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
              Padding(
                padding: const EdgeInsetsDirectional.only(bottom: 8),
                child: TextField(
                  key: const ValueKey('settings-search-field'),
                  controller: _query,
                  focusNode: _searchFocus,
                  decoration: InputDecoration(
                    isDense: true,
                    prefixIcon: const Icon(Icons.search),
                    hintText: context.l10n.settingsSearchHint,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              for (final (s, _) in shown)
                Padding(
                  padding: const EdgeInsetsDirectional.symmetric(vertical: 1),
                  child: ListTile(
                    key: ValueKey('settings-cat-${s.id}'),
                    dense: true,
                    selected: query.isEmpty && s == open.$1,
                    selectedTileColor: colors.secondaryContainer,
                    selectedColor: colors.onSecondaryContainer,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    title: Text(
                      s.title(context, _formFactor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => setState(() {
                      _open = s.id;
                      _query.clear();
                    }),
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
              child: query.isNotEmpty
                  ? SingleChildScrollView(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        16,
                        16,
                        16,
                        32,
                      ),
                      child: SettingsSearchResults(
                        hits: searchSettings(
                          context,
                          ref,
                          [for (final (s, _) in shown) s],
                          _formFactor,
                          query,
                        ),
                        formFactor: _formFactor,
                        onOpen: (hit) => _jumpTo(hit.entry.id),
                      ),
                    )
                  : SettingsJumpScope(
                      controller: _jump,
                      child: SingleChildScrollView(
                        key: ValueKey('settings-pane-${open.$1.id}'),
                        padding: const EdgeInsetsDirectional.fromSTEB(
                          16,
                          16,
                          16,
                          32,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(
                              padding: const EdgeInsetsDirectional.fromSTEB(
                                16,
                                0,
                                16,
                                8,
                              ),
                              child: Text(
                                open.$1.title(context, _formFactor),
                                style: theme.textTheme.titleLarge,
                              ),
                            ),
                            for (final e in open.$2)
                              SettingsEntryView(entry: e),
                          ],
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
