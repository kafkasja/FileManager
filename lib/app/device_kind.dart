import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/form_factor.dart';
import 'package:kfm/core/platform/host_platform.dart';

/// What KFM calls the device it runs on in texts (TASK-E2 §5): `phone`,
/// `pc` (Windows) or `other` ("this device"). The value of the `device`
/// ICU select in ARB strings like `aiLabelsEnableOn`.
String deviceKindFor(FormFactor formFactor) => !formFactor.isDesktop
    ? 'phone'
    : isWindowsHost
    ? 'pc'
    : 'other';

/// [deviceKindFor] of the app's form factor; works in any build method and
/// in settings text builders (no `ref` needed).
String deviceKind(BuildContext context) => deviceKindFor(
  ProviderScope.containerOf(context, listen: false).read(formFactorProvider),
);
