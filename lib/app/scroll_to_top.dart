import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/router.dart';

/// E4: the active tab was tapped again: its main list scrolls to the top.
/// Each tap is a new value (the serial grows), so listeners always fire.
final scrollToTopProvider = NotifierProvider<ScrollToTop, (AppTab, int)?>(
  ScrollToTop.new,
);

/// E4: Browse's folder view should scroll to this file and flash it once
/// ("Open folder" from the swipe screen or the details sheet).
final browseHighlightProvider = NotifierProvider<BrowseHighlight, String?>(
  BrowseHighlight.new,
);

class BrowseHighlight extends Notifier<String?> {
  @override
  String? build() => null;

  /// [fileId] null = done (nothing to show).
  void show(String? fileId) {
    if (state != fileId) state = fileId;
  }
}

class ScrollToTop extends Notifier<(AppTab, int)?> {
  @override
  (AppTab, int)? build() => null;

  void request(AppTab tab) => state = (tab, (state?.$2 ?? 0) + 1);
}
