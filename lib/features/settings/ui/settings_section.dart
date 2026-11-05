import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/form_factor.dart';

/// A text of a settings entry in the current language.
typedef SettingsText = String Function(BuildContext context);

/// Whether an entry shows right now (cloud rows until the first upload, AI
/// support, …). Called inside a build, so it may `ref.watch`.
typedef SettingsVisible = bool Function(WidgetRef ref);

/// One row (or a small group of rows that belong together) on the Settings
/// screen (TASK-E2 §1). Feature files own their entries and export them as
/// `List<SettingsEntry>`; `settingsSectionsProvider` groups them.
///
/// [id] is stable (`'files.bigFileThreshold'`): search results, deep links
/// (`/settings?entry=<id>`) and tests (`ValueKey('setting-<id>')`) use it.
@immutable
class SettingsEntry {
  const new({
    required this.id,
    required this.titleBuilder,
    required this.builder,
    this.subtitleBuilder,
    this.keywordsBuilder,
    this.selfExplanatory = false,
    this.formFactors = const {FormFactor.mobile, FormFactor.desktop},
    this.visible,
  });

  final String id;

  /// The row's title, also what search shows.
  final SettingsText titleBuilder;

  /// The row widget(s). Shows [subtitleBuilder] as its description.
  final WidgetBuilder builder;

  /// The one-line description (required unless [selfExplanatory]); search
  /// matches it too.
  final SettingsText? subtitleBuilder;

  /// Extra search words, comma-separated, in the current language.
  final SettingsText? keywordsBuilder;

  /// "Theme" needs no description.
  final bool selfExplanatory;

  /// Where the entry shows: phone-only rows leave out [FormFactor.desktop].
  final Set<FormFactor> formFactors;

  /// null = always.
  final SettingsVisible? visible;

  /// The key every entry's row carries.
  ValueKey<String> get key => ValueKey('setting-$id');

  bool isVisible(WidgetRef ref) => visible?.call(ref) ?? true;
}

/// One group on the Settings screen. Features add their entries in
/// `settingsSectionsProvider` instead of editing the screen. The section
/// shows only when at least one entry is visible for the form factor.
@immutable
class SettingsSection {
  const new({
    required this.order,
    required this.id,
    required this.icon,
    required this.titleBuilder,
    required this.entries,
    this.desktopTitleBuilder,
  });

  final int order;

  /// The phone overview's tile icon (one tile per section, like Android's
  /// own Settings app).
  final IconData icon;

  /// Stable, e.g. `'files'`; the desktop category key uses it.
  final String id;
  final SettingsText titleBuilder;

  /// The title on desktop when it differs ("Sorting" instead of "Swiping").
  final SettingsText? desktopTitleBuilder;
  final List<SettingsEntry> entries;

  String title(BuildContext context, FormFactor formFactor) =>
      formFactor.isDesktop
      ? (desktopTitleBuilder ?? titleBuilder)(context)
      : titleBuilder(context);

  /// The entries for [formFactor], before [SettingsEntry.visible].
  List<SettingsEntry> entriesFor(FormFactor formFactor) => [
    for (final e in entries)
      if (e.formFactors.contains(formFactor)) e,
  ];

  /// Shown on [formFactor] at all (any entry might be visible).
  bool appliesTo(FormFactor formFactor) => entriesFor(formFactor).isNotEmpty;
}
