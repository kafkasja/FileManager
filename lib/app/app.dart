import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/layout/text_scale.dart';
import 'package:kfm/app/router.dart';
import 'package:kfm/app/theme/app_theme.dart';
import 'package:kfm/app/theme/theme_providers.dart';
import 'package:kfm/core/background/in_app_jobs.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/diagnostics/error_log_providers.dart';
import 'package:kfm/core/index/index_providers.dart';
import 'package:kfm/features/ai_labels/data/ai_labels_providers.dart';
import 'package:kfm/features/cloud/data/cloud_providers.dart';
import 'package:kfm/features/connect/data/connect_providers.dart';
import 'package:kfm/features/connect/ui/windows_close_host.dart';
import 'package:kfm/features/external_storage/data/places_watcher.dart';
import 'package:kfm/features/privacy/data/privacy_providers.dart';
import 'package:kfm/features/session/data/session_providers.dart';
import 'package:kfm/features/share_in/data/share_in_service.dart';
import 'package:kfm/features/similar/data/similar_scan_job.dart';
import 'package:kfm/features/smart_groups/data/smart_groups_providers.dart';
import 'package:kfm/features/tags/data/tag_providers.dart';
import 'package:kfm/features/transfers/data/transfer_providers.dart';
import 'package:kfm/features/trash/data/trash_providers.dart';
import 'package:kfm/features/updates/data/update_checker.dart';
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
      // L1: pick up a new wallpaper palette ("System colors").
      onResume: () => ref.invalidate(systemAccentSeedProvider),
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
      // C2/C3: in-app jobs run while the index is idle and the app is in
      // front; the similar scan registers itself (idle until turned on).
      ..watch(inAppJobRunnerProvider)
      ..watch(similarScanJobProvider)
      // C5: smart groups (idle until Groups is opened once).
      ..watch(smartGroupsJobProvider)
      // C3: on-device labels (idle until turned on with models installed).
      ..watch(labelingJobProvider)
      // U1: hides index rows of detached volumes, scans mounted ones.
      ..watch(placesWatcherProvider)
      // P2: tags/favorites follow files whose id changes.
      ..watch(fileIdRekeyerProvider)
      // H5: failed queued writes also go to the error log.
      ..watch(errorLogDbBridgeProvider)
      // Recover stuck deletes, purge expired pending files (D2/D4).
      ..watch(startupMaintenanceProvider)
      // X2: delete stripped copies (shares, uploads) of earlier runs.
      ..watch(privacyStartupCleanupProvider)
      // X3: resumes cloud uploads only when a destination and unfinished
      // rows exist (two queries; no cloud channel call otherwise).
      ..watch(cloudResumeProvider)
      // X1: delete shared-in copies older than 7 days.
      ..watch(shareInCleanupProvider)
      // N6: forget temporary remembered devices after 7 days.
      ..watch(knownDevicesPurgeProvider)
      // N9: Wi-Fi transfers follow the connection as long as the app runs.
      ..watch(transferEngineProvider)
      // X7: daily update check; no request while the switch is off.
      ..watch(updateAutoCheckProvider)
      // PL1: Windows close → tray while sharing (null elsewhere).
      ..watch(windowsCloseFlowProvider)
      // PL1: sleep stops sharing, wake-up rescans (null elsewhere).
      ..watch(windowsPowerFlowProvider)
      // B9: the ⋮ menu reads favorites synchronously; listen (not watch) so
      // the set stays loaded without rebuilding the app on each change.
      ..listen(favoriteIdsProvider, (_, _) {});
    // L1: color theme; System without a wallpaper palette falls back to blue.
    final accent = ref.watch(themeAccentProvider).value ?? AppAccent.blue;
    final seed = accentSeed(
      accent,
      systemSeed: ref.watch(systemAccentSeedProvider).value,
    );
    final mono = accent == AppAccent.mono;
    // L5: System leaves the platform scaler untouched.
    final textSize = ref.watch(textSizeProvider).value ?? AppTextSize.system;
    return MaterialApp.router(
      routerConfig: ref.watch(routerProvider),
      onGenerateTitle: (context) => context.l10n.appTitle,
      theme: buildTheme(Brightness.light, seed: seed, monochrome: mono),
      darkTheme: buildTheme(Brightness.dark, seed: seed, monochrome: mono),
      themeMode: ref.watch(themeModeProvider).value ?? ThemeMode.system,
      locale: ref.watch(appLocaleProvider).value,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      builder: (context, child) =>
          applyTextScale(context, child ?? const SizedBox.shrink(), textSize),
    );
  }
}
