import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;

/// One-off reads of an async provider's value from UI code.
extension ReadFuture on WidgetRef {
  /// [provider]'s next value, listening until it arrives.
  ///
  /// `ref.read(p.future)` on an auto-dispose provider that no widget
  /// watches lets Riverpod 3 dispose it before a stream emits, and the
  /// future fails with "disposed during loading state" (monkey test: Done
  /// on the desktop Sort screen, which has no rename pill watching
  /// `renameBatchCountProvider`).
  Future<T> readFuture<T>(ProviderListenable<Future<T>> provider) async {
    final sub = listenManual(provider, (_, _) {});
    try {
      return await sub.read();
    } finally {
      sub.close();
    }
  }
}
