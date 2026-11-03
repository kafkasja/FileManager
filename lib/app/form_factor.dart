import 'dart:io';

import 'package:kfm/core/platform/host_platform.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'form_factor.g.dart';

/// Which UI KFM shows (TASK-PL3): the phone app, or the desktop app with
/// its own shell and screens (`lib/desktop/`). Everything below the UI is
/// shared.
enum FormFactor {
  mobile,
  desktop;

  bool get isDesktop => this == desktop;
}

/// The one switch between the phone and the desktop UI. `desktop` on
/// Windows (and later macOS/Linux) hosts, `mobile` everywhere else. Tests
/// override it (the test config runs the app as Android on any host).
@Riverpod(keepAlive: true)
FormFactor formFactor(Ref ref) =>
    isWindowsHost || (!_inTests && (Platform.isMacOS || Platform.isLinux))
    ? FormFactor.desktop
    : FormFactor.mobile;

/// `flutter test` on a Linux/macOS box must still run the mobile UI.
bool get _inTests => Platform.environment.containsKey('FLUTTER_TEST');
