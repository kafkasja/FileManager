import 'dart:io';

import 'package:meta/meta.dart';

/// Tests set this (`test/flutter_test_config.dart`: false) so a Windows dev
/// machine runs the app's tests like any other host: no directory watchers
/// on the real Pictures folder, no Windows-only settings section.
@visibleForTesting
bool? debugWindowsHostOverride;

/// KFM runs as the Windows desktop app (TASK-PL1). Features ask this
/// instead of `Platform.isWindows`.
bool get isWindowsHost => debugWindowsHostOverride ?? Platform.isWindows;
