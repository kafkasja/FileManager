import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/form_factor.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/theme/app_tokens.dart';
import 'package:kfm/features/settings/ui/settings_entry_view.dart';
import 'package:kfm/features/settings/ui/settings_search.dart';
import 'package:kfm/features/settings/ui/settings_sections.dart';

/// Built from `settingsSectionsProvider`; never add rows here directly.
/// The search action filters every entry (TASK-E2 §3); [entry] (the
/// `/settings?entry=<id>` deep link) scrolls to that entry and flashes it.
class SettingsScreen extends ConsumerStatefulWidget {
  const new({this.entry, super.key});

  final String? entry;

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _jump = SettingsJumpController();
  final _query = TextEditingController();
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    if (widget.entry case final id?) _jump.jumpTo(id);
  }

  @override
  void didUpdateWidget(SettingsScreen old) {
    super.didUpdateWidget(old);
    if (widget.entry case final id? when id != old.entry) _jump.jumpTo(id);
  }

  @override
  void dispose() {
    _jump.dispose();
    _query.dispose();
    super.dispose();
  }

  void _closeSearch() => setState(() {
    _searching = false;
    _query.clear();
  });

  void _open(SettingsSearchHit hit) {
    _closeSearch();
    _jump.jumpTo(hit.entry.id);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final formFactor = ref.watch(formFactorProvider);
    final sections = ref.watch(settingsSectionsProvider);
    final spacing = context.tokens.spacing;
    final theme = Theme.of(context);
    final query = _query.text.trim();
    return Scaffold(
      appBar: AppBar(
        title: _searching
            ? TextField(
                key: const ValueKey('settings-search-field'),
                controller: _query,
                autofocus: true,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: l10n.settingsSearchHint,
                  border: InputBorder.none,
                ),
                onChanged: (_) => setState(() {}),
              )
            : Text(l10n.settingsTitle),
        leading: _searching ? BackButton(onPressed: _closeSearch) : null,
        actions: [
          if (!_searching)
            IconButton(
              key: const ValueKey('settings-search'),
              tooltip: l10n.settingsSearchHint,
              icon: const Icon(Icons.search),
              onPressed: () => setState(() => _searching = true),
            )
          else if (query.isNotEmpty)
            IconButton(
              tooltip: l10n.settingsSearchClear,
              icon: const Icon(Icons.close),
              onPressed: () => setState(_query.clear),
            ),
        ],
      ),
      body: _searching && query.isNotEmpty
          ? SingleChildScrollView(
              child: SettingsSearchResults(
                hits: searchSettings(context, ref, sections, formFactor, query),
                formFactor: formFactor,
                onOpen: _open,
              ),
            )
          : SettingsJumpScope(
              controller: _jump,
              // Every entry is built so a jump can scroll to any of them.
              child: SingleChildScrollView(
                padding: EdgeInsetsDirectional.only(bottom: spacing * 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final section in sections)
                      if (visibleEntries(ref, section, formFactor)
                          case final entries when entries.isNotEmpty) ...[
                        Padding(
                          key: ValueKey('settings-section-${section.id}'),
                          padding: EdgeInsetsDirectional.fromSTEB(
                            spacing * 2,
                            spacing * 3,
                            spacing * 2,
                            spacing,
                          ),
                          child: Text(
                            section.title(context, formFactor),
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                        for (final e in entries) SettingsEntryView(entry: e),
                      ],
                  ],
                ),
              ),
            ),
    );
  }
}
