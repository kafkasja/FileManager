import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/router.dart';

/// E4: the active tab was tapped again: its main list scrolls to the top.
/// Each tap is a new value (the serial grows), so listeners always fire.
final scrollToTopProvider = NotifierProvider<ScrollToTop, (AppTab, int)?>(
  ScrollToTop.new,
);

class ScrollToTop extends Notifier<(AppTab, int)?> {
  @override
  (AppTab, int)? build() => null;

  void request(AppTab tab) => state = (tab, (state?.$2 ?? 0) + 1);
}
