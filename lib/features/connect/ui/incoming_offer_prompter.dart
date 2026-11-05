import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kfm/app/file_reveal.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/router.dart';
import 'package:kfm/app/safe_nav.dart';
import 'package:kfm/core/files/file_kind_resolver.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/files/file_source_provider.dart';
import 'package:kfm/core/utils/format.dart';
import 'package:kfm/core/utils/read_future.dart';
import 'package:kfm/features/connect/data/connect_providers.dart';
import 'package:kfm/features/connect/data/offer_service.dart';
import 'package:kfm/features/connect/data/share_background.dart';
import 'package:kfm/features/connect/domain/fingerprint_words.dart';
import 'package:kfm/features/connect/domain/known_device.dart';
import 'package:kfm/features/connect/domain/offer_protocol.dart';
import 'package:kfm/features/connect/domain/remote_connection_state.dart';
import 'package:kfm/features/connect/domain/remote_file_id.dart';
import 'package:kfm/features/connect/domain/share_offer.dart';
import 'package:kfm/features/connect/ui/link_controller.dart';
import 'package:kfm/features/connect/ui/offer_dialog.dart';
import 'package:kfm/features/connect/ui/remote_connection_controller.dart';
import 'package:kfm/features/details/ui/file_details_sheet.dart';
import 'package:kfm/features/folders/ui/folder_picker_sheet.dart';
import 'package:kfm/features/transfers/data/offer_client.dart';
import 'package:kfm/features/transfers/data/transfer_engine.dart';
import 'package:kfm/features/transfers/data/transfer_providers.dart';
import 'package:kfm/features/transfers/domain/transfer_job.dart';
import 'package:path/path.dart' as p;

/// N12b: the remote file a client downloads for an offered [f] (null
/// without the server's file id).
FileRef? offeredRemoteFile(String peerFingerprint, OfferFileDto f) {
  final id = f.id;
  if (id == null) return null;
  return FileRef(
    id: remoteFileId(peerFingerprint, id),
    uri: '',
    name: f.name,
    mimeType: f.mime,
    kind: kindFor(f.mime, f.name),
    sizeBytes: f.size,
    modifiedAt: DateTime.fromMillisecondsSinceEpoch(
      f.modifiedAtMs ?? 0,
      isUtc: true,
    ),
    folderPath: '',
    origin: FileOrigin.remote,
  );
}

/// Opens [folder] in Browse's folder layout (N12 "Received … · Open");
/// E1: on desktop its Explorer-like Browse (the phone route was used).
Future<void> openReceivedFolder(
  BuildContext context,
  WidgetRef ref,
  String folder,
) async {
  openFolderInBrowse(context, folder);
}

/// E1: the dart:io path of a received file's local id (`path:` directly,
/// `ms:` through the file source); null when unknown.
Future<String?> localPathOfReceived(WidgetRef ref, String? fileId) async {
  if (fileId == null) return null;
  if (fileId.startsWith('path:')) return fileId.substring('path:'.length);
  try {
    return (await ref.read(fileSourceProvider).stat(fileId))?.path;
  } on Object {
    return null;
  }
}

/// E1: "cat.mp4 saved to Downloads › KFM › Phone" + Show in folder, Open,
/// Copy path after a receive (either direction).
Future<void> showReceivedSnackBar(
  BuildContext context,
  WidgetRef ref, {
  required String folder,
  required List<({String name, String? fileId})> files,
}) async {
  if (files.isEmpty) return;
  final path = files.length == 1
      ? await localPathOfReceived(ref, files.single.fileId)
      : null;
  if (!context.mounted) return;
  final l10n = context.l10n;
  final where = prettyFolder(
    path == null ? folder : p.posix.dirname(path),
    downloads: platformDownloadsFolder(),
  );
  showSavedSnackBar(
    context,
    ref,
    text: files.length == 1
        ? l10n.receivedSavedOne(
            path == null ? files.single.name : p.posix.basename(path),
            where,
          )
        : l10n.receivedSavedMany(files.length, where),
    folder: folder,
    path: path,
  );
}

/// TASK-N12, mounted once in the app shell. Draws nothing:
/// - shows the offer dialog for incoming offers (one at a time, root
///   navigator, on any screen); an offer that ends elsewhere closes it;
/// - in the background (N5b) posts the "Incoming files" notification;
/// - receiver snackbars ("Receiving …", "Received … · Open");
/// - sender snackbars when a send's offer is answered.
class IncomingOfferPrompter extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<IncomingOfferPrompter> createState() =>
      _IncomingOfferPrompterState();
}

class _IncomingOfferPrompterState extends ConsumerState<IncomingOfferPrompter>
    with WidgetsBindingObserver {
  ProviderSubscription<AsyncValue<List<OfferPrompt>>>? _promptsSub;
  ProviderSubscription<AsyncValue<List<TransferJob>>>? _jobsSub;
  StreamSubscription<OfferEvent>? _eventsSub;

  /// The offer whose dialog is open.
  String? _dialogFor;
  final DialogHandle<OfferAnswer> _dialog = DialogHandle();

  /// N12b: the inbox offer (from the device we're connected to) whose
  /// dialog is open; inbox offers already answered or auto-accepted.
  String? _inboxDialogFor;
  final DialogHandle<OfferAnswer> _inboxDialog = DialogHandle();
  final Set<String> _handledInbox = {};
  ProviderSubscription<List<OfferDto>>? _inboxSub;
  final Set<String> _notified = {};

  /// Send jobs last seen waiting for an answer.
  final Set<String> _awaiting = {};

  /// E1: download jobs last seen unfinished ("… saved to …" when done).
  final Set<String> _downloading = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _promptsSub = ref.listenManual(
      offerPromptsProvider,
      (_, next) => _onPrompts(next.value ?? const []),
    );
    _eventsSub = ref.read(offerServiceProvider).events.listen(_onEvent);
    _jobsSub = ref.listenManual(
      transferJobsProvider,
      (_, next) => _onJobs(next.value ?? const []),
    );
    _inboxSub = ref.listenManual(
      remoteInboxProvider,
      (_, next) => _onInbox(next),
    );
    // The current values after the first frame (l10n and the navigator
    // aren't ready inside initState).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _onJobs(ref.read(transferJobsProvider).value ?? const []);
      _onPrompts(ref.read(offerPromptsProvider).value ?? const []);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _promptsSub?.close();
    _jobsSub?.close();
    _inboxSub?.close();
    unawaited(_eventsSub?.cancel());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_background.cancelOffer().catchError((Object _) {}));
      _onPrompts(ref.read(offerPromptsProvider).value ?? const []);
    }
  }

  ShareBackground get _background => ref.read(shareBackgroundProvider);

  bool get _foreground {
    final s = WidgetsBinding.instance.lifecycleState;
    return s == null || s == AppLifecycleState.resumed;
  }

  void _onPrompts(List<OfferPrompt> prompts) {
    if (!mounted) return;
    final open = _dialogFor;
    if (open != null && !prompts.any((p) => p.offer.id == open)) {
      // Ended elsewhere (expired, cancelled, stop sharing).
      _dialogFor = null;
      _dialog.close();
    }
    _notified.removeWhere((id) => !prompts.any((p) => p.offer.id == id));
    if (prompts.isEmpty) {
      unawaited(_background.cancelOffer().catchError((Object _) {}));
      return;
    }
    final next = prompts.first;
    if (!_foreground) {
      if (_notified.add(next.offer.id)) unawaited(_notify(next));
      return;
    }
    if (_dialogFor == null && _inboxDialogFor == null) {
      unawaited(_show(next));
    }
  }

  Future<void> _notify(OfferPrompt p) async {
    final l10n = context.l10n;
    try {
      await _background.showOffer(
        OfferNotificationTexts(
          channel: l10n.offerNotificationChannel,
          title: l10n.offerNotificationTitle(p.offer.peerName),
          text: l10n.offerNotificationBody(
            p.offer.fileCount,
            formatBytes(p.offer.totalBytes),
          ),
        ),
      );
    } on Object catch (e) {
      // Notifications denied: the offer waits until KFM is opened.
      developer.log('offer notification failed: $e', name: 'kfm.connect');
    }
  }

  Future<void> _show(OfferPrompt p) async {
    final o = p.offer;
    _dialogFor = o.id;
    unawaited(HapticFeedback.mediumImpact().catchError((Object _) {}));
    unawaited(
      SystemSound.play(SystemSoundType.alert).catchError((Object _) {}),
    );
    final answer = await _dialog.show(
      context,
      barrierDismissible: false,
      builder: (_) => OfferDialog(
        data: OfferDialogData(
          offerId: o.id,
          senderName: o.peerName,
          platform: p.platform,
          words: p.words,
          names: [for (final f in o.files) f.name],
          totalBytes: o.totalBytes,
          defaultFolder: p.defaultFolder,
          deadline: o.expiresAt,
          showRemember: !p.remembered,
        ),
        pickFolder: showFolderPicker,
      ),
    );
    if (_dialogFor == o.id) _dialogFor = null;
    if (!mounted) return;
    if (answer != null) {
      try {
        await ref
            .read(offerServiceProvider)
            .decide(
              o.id,
              accept: answer.accept,
              folder: answer.folder,
              remember: answer.remember,
              alwaysAccept: answer.alwaysAccept,
            );
        if (answer.accept && mounted) {
          _snack(context.l10n.offerReceiving(o.fileCount, o.peerName));
        }
      } on OfferFolderRefused {
        // An excluded folder (the dialog refuses those already).
        if (mounted) _snack(context.l10n.offerFolderExcluded);
      }
    }
    _next();
  }

  /// The next prompt in either queue, if any.
  void _next() {
    if (!mounted) return;
    _onPrompts(ref.read(offerPromptsProvider).value ?? const []);
    _onInbox(ref.read(remoteInboxProvider));
  }

  // ---- N12b: offers the device we're connected to makes to us ----

  void _onInbox(List<OfferDto> offers) {
    if (!mounted) return;
    final open = _inboxDialogFor;
    if (open != null && !offers.any((o) => o.id == open)) {
      // Taken back or expired over there. Closes nothing while the prompt
      // is still being prepared (E1 H3: that pop emptied the navigator).
      _inboxDialogFor = null;
      _inboxDialog.close();
    }
    final c = ref.read(remoteConnectionControllerProvider);
    if (c is! RemoteConnected || !_foreground) return;
    if (_dialogFor != null || _inboxDialogFor != null) return;
    final next = offers
        .where(
          (o) =>
              o.status == OfferWireStatus.pending &&
              !_handledInbox.contains(o.id),
        )
        .firstOrNull;
    if (next == null) return;
    if (!isAcceptableInboxOffer(next)) {
      // Too many files, a bad name or no file id: checked like any sender,
      // refused without a prompt.
      _handledInbox.add(next.id);
      ref.read(remoteInboxProvider.notifier).remove(next.id);
      final http = ref.read(remoteConnectionControllerProvider.notifier).http;
      if (http != null) {
        unawaited(OfferClient(http).decline(next.id).catchError((Object _) {}));
      }
      _next();
      return;
    }
    unawaited(_showInbox(next, c));
  }

  Future<void> _showInbox(OfferDto o, RemoteConnected c) async {
    _handledInbox.add(o.id);
    _inboxDialogFor = o.id;
    final l10n = context.l10n;
    final fp = c.peerFingerprint;
    final devices = ref.read(knownDevicesRepositoryProvider);
    final known = await devices.byFingerprint(fp);
    // A remembered name wins over what the offer claims; the name only
    // labels the prompt and the Download/<name> folder.
    final name = known?.name ?? c.peerName;
    final folder = defaultDownloadFolder(ref.read(downloadsRootProvider), name);
    if (!mounted) return;
    if (_inboxDialogFor != o.id) {
      // Taken back (or the connection ended) while we looked it up.
      _next();
      return;
    }
    OfferAnswer? answer;
    // E1: files from the linked device need no prompt.
    final linked = ref.read(linkControllerProvider)?.peerFingerprint == fp;
    if (linked ||
        (known != null && !known.isTemporary && known.autoAcceptFiles)) {
      // Trusted: no prompt.
      answer = (
        accept: true,
        folder: folder,
        remember: true,
        alwaysAccept: true,
      );
    } else {
      unawaited(HapticFeedback.mediumImpact().catchError((Object _) {}));
      final me = await ref.readFuture(deviceIdentityProvider.future);
      if (!mounted) return;
      if (_inboxDialogFor != o.id) {
        // Taken back while we looked it up.
        _next();
        return;
      }
      answer = await _inboxDialog.show(
        context,
        barrierDismissible: false,
        builder: (_) => OfferDialog(
          data: OfferDialogData(
            offerId: o.id,
            senderName: name,
            platform: known?.platform ?? '',
            words: fingerprintWords(fp, me.fingerprint),
            names: [for (final f in o.files) f.name],
            totalBytes: o.files.fold(0, (a, f) => a + f.size),
            defaultFolder: folder,
            deadline: DateTime.now().add(
              Duration(seconds: o.expiresInSeconds ?? 120),
            ),
            showRemember: known == null || known.isTemporary,
          ),
          pickFolder: showFolderPicker,
        ),
      );
    }
    if (_inboxDialogFor == o.id) _inboxDialogFor = null;
    if (!mounted) return;
    final http = ref.read(remoteConnectionControllerProvider.notifier).http;
    if (answer != null && http != null) {
      ref.read(remoteInboxProvider.notifier).remove(o.id);
      try {
        final client = OfferClient(http);
        if (!answer.accept) {
          await client.decline(o.id);
        } else {
          await client.accept(o.id);
          if (answer.remember || answer.alwaysAccept) {
            await devices.saveAfterPairing(
              PairedPeer(
                fingerprint: fp,
                peerDeviceId: known?.peerDeviceId ?? '',
                name: name,
                platform: known?.platform ?? '',
                canShareToUs: true,
              ),
              temporary: false,
            );
            if (answer.alwaysAccept) {
              await devices.setAutoAcceptFiles(fp, enabled: true);
            }
          }
          await ref
              .read(transferEngineProvider)
              .enqueueDownload(
                [for (final f in o.files) ?offeredRemoteFile(fp, f)],
                peerFingerprint: fp,
                peerName: name,
                localFolder: answer.folder,
                inboxOfferId: o.id,
              );
          if (mounted) _snack(l10n.offerReceiving(o.files.length, name));
        }
      } on Object catch (e) {
        developer.log('offer answer failed: $e', name: 'kfm.connect');
        if (mounted) _snack(l10n.transferLostConnection(name));
      }
    }
    _next();
  }

  void _onEvent(OfferEvent e) {
    if (!mounted) return;
    final l10n = context.l10n;
    switch (e) {
      case OfferAutoAccepted(:final offer):
        _snack(l10n.offerReceiving(offer.fileCount, offer.peerName));
      case OfferReceived(:final offer):
        final folder = offer.folder;
        if (folder == null) {
          _snack(l10n.offerReceived(offer.fileCount, offer.peerName));
          return;
        }
        // E1: where it landed, with Show in folder / Open / Copy path.
        unawaited(
          showReceivedSnackBar(
            context,
            ref,
            folder: folder,
            files: [
              for (final f in offer.files)
                if (f.status == OfferFileStatus.done)
                  (name: f.name, fileId: f.localFileId),
            ],
          ),
        );
    }
  }

  void _onJobs(List<TransferJob> jobs) {
    if (!mounted) return;
    final l10n = context.l10n;
    for (final j in jobs) {
      _onDownload(j);
      if (!j.isOffer) continue;
      if (j.awaitingAccept) {
        _awaiting.add(j.id);
        continue;
      }
      if (!_awaiting.remove(j.id)) continue;
      final error = j.files
          .map((f) => f.error)
          .where((e) => e != null)
          .firstOrNull;
      final text = switch (error) {
        TransferErrors.offerDeclined => l10n.sendDeclined(j.deviceName),
        TransferErrors.offerExpired => l10n.sendNoAnswer(j.deviceName),
        TransferErrors.offerNoSpace => l10n.sendNoSpace(j.deviceName),
        TransferErrors.offerCancelled => l10n.sendStopped(j.deviceName),
        _ when !j.isFinished => l10n.sendSending(j.files.length, j.deviceName),
        _ => null,
      };
      if (text != null) _snack(text, showTransfers: true);
    }
  }

  /// E1: a download (from the connected device) finished: where it landed.
  void _onDownload(TransferJob j) {
    if (j.direction != TransferDirection.download) return;
    if (!j.isFinished) {
      _downloading.add(j.id);
      return;
    }
    if (!_downloading.remove(j.id)) return;
    final done = [
      for (final f in j.files)
        if (f.status == TransferFileStatus.done)
          (name: f.name, fileId: f.targetFileId),
    ];
    if (done.isEmpty) return;
    unawaited(
      showReceivedSnackBar(context, ref, folder: j.targetPath, files: done),
    );
  }

  void _snack(
    String text, {
    SnackBarAction? action,
    bool showTransfers = false,
  }) {
    final router = GoRouter.of(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          persist: false,
          content: Text(text),
          action:
              action ??
              (showTransfers
                  ? SnackBarAction(
                      label: context.l10n.transferShow,
                      onPressed: () => router.push(AppRoutes.transfers),
                    )
                  : null),
        ),
      );
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
