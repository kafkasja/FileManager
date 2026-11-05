import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kfm/app/form_factor.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/router.dart';
import 'package:kfm/app/theme/app_tokens.dart';
import 'package:kfm/features/settings/ui/settings_entry_view.dart';
import 'package:kfm/features/settings/ui/settings_search.dart';
import 'package:kfm/features/settings/ui/settings_section.dart';
import 'package:kfm/features/settings/ui/settings_sections.dart';

/// The phone's Settings overview (like Android's own Settings app): one
/// tile per visible section with its icon and a one-line summary; a tap
/// opens [SettingsSectionScreen]. Built from `settingsSectionsProvider`;
/// never add rows here directly. The search action filters every entry
/// (TASK-E2 §3) and opens the entry's section page. `/settings?entry=<id>`
/// is redirected to that page by the router. Desktop has its own screen.
class SettingsScreen extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _query = TextEditingController();
  bool _searching = false;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  void _closeSearch() => setState(() {
    _searching = false;
    _query.clear();
  });

  void _open(SettingsSearchHit hit) {
    _closeSearch();
    unawaited(
      context.push(
        AppRoutes.settingsSection(hit.section.id, entry: hit.entry.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final formFactor = ref.watch(formFactorProvider);
    final sections = ref.watch(settingsSectionsProvider);
    final spacing = context.tokens.spacing;
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
          : ListView(
              padding: EdgeInsetsDirectional.symmetric(vertical: spacing),
              children: [
                for (final section in sections)
                  if (visibleEntries(ref, section, formFactor)
                      case final entries when entries.isNotEmpty)
                    ListTile(
                      key: ValueKey('settings-section-${section.id}'),
                      leading: Icon(section.icon),
                      title: Text(section.title(context, formFactor)),
                      subtitle: Text(
                        sectionSummary(context, entries),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () =>
                          context.push(AppRoutes.settingsSection(section.id)),
                    ),
              ],
            ),
    );
  }
}

/// "Theme, Color, Language": the first three visible entry titles.
@visibleForTesting
String sectionSummary(BuildContext context, List<SettingsEntry> entries) {
  final titles = <String>[];
  for (final e in entries) {
    final t = e.titleBuilder(context);
    if (!titles.contains(t)) titles.add(t);
    if (titles.length == 3) break;
  }
  return titles.join(context.l10n.settingsSummarySeparator);
}

/// One section's entries on its own page (`/settings/section/<id>`);
/// [entry] scrolls to that entry and flashes it.
class SettingsSectionScreen extends ConsumerStatefulWidget {
  const new({required this.sectionId, this.entry, super.key});

  final String sectionId;
  final String? entry;

  @override
  ConsumerState<SettingsSectionScreen> createState() =>
      _SettingsSectionScreenState();
}

class _SettingsSectionScreenState extends ConsumerState<SettingsSectionScreen> {
  final _jump = SettingsJumpController();

  @override
  void initState() {
    super.initState();
    if (widget.entry case final id?) _jump.jumpTo(id);
  }

  @override
  void didUpdateWidget(SettingsSectionScreen old) {
    super.didUpdateWidget(old);
    if (widget.entry case final id? when id != old.entry) _jump.jumpTo(id);
  }

  @override
  void dispose() {
    _jump.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formFactor = ref.watch(formFactorProvider);
    final section = ref
        .watch(settingsSectionsProvider)
        .where((s) => s.id == widget.sectionId)
        .firstOrNull;
    final spacing = context.tokens.spacing;
    final entries = section == null
        ? const <SettingsEntry>[]
        : visibleEntries(ref, section, formFactor);
    return Scaffold(
      appBar: AppBar(
        title: Text(section?.title(context, formFactor) ?? ''),
      ),
      body: SettingsJumpScope(
        controller: _jump,
        // Every entry is built so a jump can scroll to any of them.
        child: SingleChildScrollView(
          key: ValueKey('settings-page-${widget.sectionId}'),
          padding: EdgeInsetsDirectional.only(
            top: spacing,
            bottom: spacing * 2,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [for (final e in entries) SettingsEntryView(entry: e)],
          ),
        ),
      ),
    );
  }
}
