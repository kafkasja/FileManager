import 'package:flutter/widgets.dart';

/// One group on the Settings screen. Features register theirs in
/// `settingsSectionsProvider` instead of editing the screen.
///
/// Orders: 100 Appearance, 200 Swipe, 300 Deleting, 400 Permissions,
/// 500 Storage, 900 About.
@immutable
class SettingsSection {
  const new({
    required this.order,
    required this.titleBuilder,
    required this.builder,
  });

  final int order;
  final String Function(BuildContext context) titleBuilder;
  final WidgetBuilder builder;
}
