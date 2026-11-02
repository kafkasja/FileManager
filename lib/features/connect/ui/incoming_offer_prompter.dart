import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/router.dart';
import 'package:kfm/core/utils/format.dart';
import 'package:kfm/features/browse/domain/browse_source_chip.dart';
import 'package:kfm/features/browse/ui/browse_controller.dart';
import 'package:kfm/features/connect/data/connect_providers.dart';
import 'package:kfm/features/connect/data/offer_service.dart';
import 'package:kfm/features/connect/data/share_background.dart';
import 'package:kfm/features/connect/ui/offer_dialog.dart';
import 'package:kfm/features/folders/ui/folder_picker_sheet.dart';
import 'package:kfm/features/transfers/data/transfer_providers.dart';
import 'package:kfm/features/transfers/domain/transfer_job.dart';

/// Opens [folder] in Browse's folder layout (N12 "Received … · Open").
Future<void> openReceivedFolder(
  BuildContext context,
  WidgetRef ref,
  String folder,
) async {
  context.go(AppRoutes.browse);
  // The Browse tab may only now be built: set its folder after this frame.
  await WidgetsBinding.instance.endOfFrame;
  if (!context.mounted) return;
  ref.read(browseViewControllerProvider.notifier)
    ..setLayout(BrowseLayout.folders)
    ..openFolder(folder);
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
  final Set<String> _notified = {};

  /// Send jobs last seen waiting for an answer.
  final Set<String> _awaiting = {};

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
      Navigator.of(context, rootNavigator: true).pop();
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
    if (_dialogFor == null) unawaited(_show(next));
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
    final answer = await showDialog<OfferAnswer>(
      context: context,
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
    // The next one in the queue, if any.
    if (mounted) _onPrompts(ref.read(offerPromptsProvider).value ?? const []);
  }

  void _onEvent(OfferEvent e) {
    if (!mounted) return;
    final l10n = context.l10n;
    switch (e) {
      case OfferAutoAccepted(:final offer):
        _snack(l10n.offerReceiving(offer.fileCount, offer.peerName));
      case OfferReceived(:final offer):
        final folder = offer.folder;
        _snack(
          l10n.offerReceived(offer.fileCount, offer.peerName),
          action: folder == null
              ? null
              : SnackBarAction(
                  label: l10n.offerOpenFolder,
                  onPressed: () =>
                      unawaited(openReceivedFolder(context, ref, folder)),
                ),
        );
    }
  }

  void _onJobs(List<TransferJob> jobs) {
    if (!mounted) return;
    final l10n = context.l10n;
    for (final j in jobs) {
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
