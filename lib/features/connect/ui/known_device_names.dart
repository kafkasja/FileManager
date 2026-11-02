import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/features/connect/data/connect_providers.dart';
import 'package:kfm/features/connect/domain/known_device.dart';

/// The remembered device [id]'s name (N9 swipe send labels); null when it
/// isn't known (or the list isn't loaded yet).
String? knownDeviceName(WidgetRef ref, String? id) {
  if (id == null) return null;
  for (final d
      in ref.read(knownDevicesProvider).value ?? const <KnownDevice>[]) {
    if (d.id == id) return d.name;
  }
  return null;
}
