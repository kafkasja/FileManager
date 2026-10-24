import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/router.dart';
import 'package:kfm/app/theme/app_theme.dart';
import 'package:kfm/app/theme/theme_providers.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/index/index_providers.dart';
import 'package:kfm/features/session/data/session_providers.dart';
import 'package:kfm/features/tags/data/tag_providers.dart';
import 'package:kfm/features/trash/data/trash_providers.dart';
import 'package:kfm/l10n/generated/app_localizations.dart';

class App extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // Land queued writes before Android may kill the process.
    _lifecycle = AppLifecycleListener(
      onPause: _flush,
      onHide: _flush,
      onDetach: _flush,
    );
  }

  /// Session progress (debounced) + every queued write.
  Future<void> _flush() async {
    await ref.read(sessionRepositoryProvider).flush();
    await ref.read(dbWriteQueueProvider).flush();
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Lives as long as the app; starts scanning once access is granted.
    ref
      ..watch(mediaIndexerProvider)
      // P2: tags/favorites follow files whose id changes.
      ..watch(fileIdRekeyerProvider)
      // Recover stuck deletes, purge expired pending files (D2/D4).
      ..watch(startupMaintenanceProvider);
    return MaterialApp.router(
      routerConfig: ref.watch(routerProvider),
      onGenerateTitle: (context) => context.l10n.appTitle,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: ref.watch(themeModeProvider).value ?? ThemeMode.system,
      locale: ref.watch(appLocaleProvider).value,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
    );
  }
}
