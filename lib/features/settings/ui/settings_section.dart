import 'package:flutter/widgets.dart';
import 'package:kfm/app/form_factor.dart';

/// One group on the Settings screen. Features register theirs in
/// `settingsSectionsProvider` instead of editing the screen.
///
/// Orders: 100 Appearance, 150 Accessibility, 200 Swipe, 250 Browse,
/// 260 Search, 300 Deleting, 350 Files, 400 Permissions, 500 Storage,
/// 900 About.
@immutable
class SettingsSection {
  const new({
    required this.order,
    required this.titleBuilder,
    required this.builder,
    this.formFactors = const {FormFactor.mobile, FormFactor.desktop},
  });

  final int order;
  final String Function(BuildContext context) titleBuilder;
  final WidgetBuilder builder;

  /// Where the section shows (TASK-PL3): phone-only sections (Android
  /// permissions, MediaStore) leave out [FormFactor.desktop].
  final Set<FormFactor> formFactors;
}
