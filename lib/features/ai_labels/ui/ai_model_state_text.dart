import 'package:kfm/features/ai_labels/data/ai_model_store.dart';
import 'package:kfm/l10n/generated/app_localizations.dart';

double _mb(int bytes) => bytes / 1000000;

/// One line describing [s] (Settings section and details screen);
/// [totalBytes] = the manifest's set size.
String aiModelStateText(
  AppLocalizations l10n,
  AiModelState s, {
  required int totalBytes,
}) => switch (s) {
  AiModelsChecking() => l10n.aiModelsChecking,
  AiModelsNotInstalled(needsUpdate: true) => l10n.aiModelsNeedUpdate,
  AiModelsNotInstalled(:final partialBytes) when partialBytes > 0 =>
    l10n.aiModelsPartial(_mb(partialBytes), _mb(totalBytes)),
  AiModelsNotInstalled() => l10n.aiModelsNotDownloaded,
  AiModelsWaitingForWifi() => l10n.aiModelsWaitingWifi,
  AiModelsDownloading(:final doneBytes, :final totalBytes) =>
    l10n.aiModelsDownloading(_mb(doneBytes), _mb(totalBytes)),
  AiModelsVerifying() => l10n.aiModelsVerifying,
  AiModelsInstalled(:final totalBytes) => l10n.aiModelsInstalled(
    _mb(totalBytes),
  ),
  AiModelsFailed(:final reason, :final detail) => switch (reason) {
    AiModelFailure.network => l10n.aiModelsErrorNetwork,
    AiModelFailure.http => l10n.aiModelsErrorHttp(detail ?? '?'),
    AiModelFailure.checksum => l10n.aiModelsErrorChecksum,
    AiModelFailure.diskFull => l10n.aiModelsErrorDiskFull,
    AiModelFailure.other => l10n.aiModelsErrorOther,
  },
};
