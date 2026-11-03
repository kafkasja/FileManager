import 'dart:async';

import 'package:kfm/core/platform/host_platform.dart';

/// Runs before every test file under test/ (flutter_test convention).
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // The app's tests describe the Android/default behaviour even on a
  // Windows dev machine; Windows-only parts have their own tests.
  debugWindowsHostOverride = false;
  await testMain();
}
