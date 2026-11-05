import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/features/swipe/ui/swipe_settings_section.dart'
    show hapticsEnabledProvider;

/// E4 (A8): the one light vibration outside swiping (copy path, pull to
/// refresh, entering Select, the end of a scrollbar drag). Respects the
/// Vibration setting; nothing else vibrates (simple by default).
void lightHaptic(WidgetRef ref) {
  if (ref.read(hapticsEnabledProvider).value ?? true) {
    HapticFeedback.lightImpact().ignore();
  }
}
