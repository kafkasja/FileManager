import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/desktop/shell/desktop_location.dart';
import 'package:kfm/desktop/tabs/desktop_tabs_controller.dart';

/// Opens [folder] in the active desktop tab (nav pane, drives, details
/// sheet); [newTab] opens it next to it.
void openDesktopFolder(
  BuildContext context,
  WidgetRef ref,
  String folder, {
  bool newTab = false,
}) {
  final tabs = ref.read(desktopTabsControllerProvider.notifier);
  if (newTab) {
    tabs.openInNewTab(FolderLocation(folder));
  } else {
    tabs.navigate(FolderLocation(folder));
  }
}
