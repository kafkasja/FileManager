import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:kfm/core/files/file_names.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/utils/random_id.dart';
import 'package:kfm/features/connect/data/client_session_store.dart';
import 'package:kfm/features/connect/data/known_devices_dao.dart';
import 'package:kfm/features/connect/data/offer_limiter.dart';
import 'package:kfm/features/connect/data/path_guard.dart';
import 'package:kfm/features/connect/data/share_offers_dao.dart';
import 'package:kfm/features/connect/data/upload_store.dart';
import 'package:kfm/features/connect/domain/connection_request.dart';
import 'package:kfm/features/connect/domain/fingerprint_words.dart';
import 'package:kfm/features/connect/domain/known_device.dart';
import 'package:kfm/features/connect/domain/offer_protocol.dart';
import 'package:kfm/features/connect/domain/protocol.dart';
import 'package:kfm/features/connect/domain/share_offer.dart';
import 'package:kfm/features/connect/domain/share_scope.dart';
import 'package:kfm/features/connect/domain/upload_protocol.dart';
import 'package:meta/meta.dart';

/// What the allow-list guard and the upload routes ask about offer grants
/// (TASK-N12). Implemented by [OfferService].
abstract interface class OfferGrants {
  /// The folder an accepted push offer of [clientFingerprint] uploads
  /// into, as a writable root with id [rootId]; null when there is no
  /// such grant (not accepted, another owner, ended).
  Future<SharedRoot?> inboxRoot(String clientFingerprint, String rootId);

  /// Matches a new upload to the first unclaimed offered file with that
  /// [name] and a size up to the offered size + [kOfferSizeSlackBytes].
  /// The same [uploadId] again passes.
  Future<bool> claim({
    required String offerId,
    required String clientFingerprint,
    required String name,
    required int size,
    required String uploadId,
  });

  /// The upload was published as [finalId].
  Future<void> completed(String uploadId, String finalId);

  /// The sender dropped the upload (its file may be claimed again).
  Future<void> released(String uploadId);

  /// N12b: the local file id behind the opaque offered id [fileId]
  /// (`offered-<offerId>-<seq>`) when it is a file of an accepted offer
  /// this device made to [clientFingerprint] (READ only); else null.
  Future<String?> offeredFileId(String clientFingerprint, String fileId);
}

/// No offers (tests and the N4 guard without N12).
class NoOfferGrants implements OfferGrants {
  const new();

  @override
  Future<SharedRoot?> inboxRoot(
    String clientFingerprint,
    String rootId,
  ) async => null;

  @override
  Future<bool> claim({
    required String offerId,
    required String clientFingerprint,
    required String name,
    required int size,
    required String uploadId,
  }) async => false;

  @override
  Future<void> completed(String uploadId, String finalId) async {}

  @override
  Future<void> released(String uploadId) async {}

  @override
  Future<String?> offeredFileId(
    String clientFingerprint,
    String fileId,
  ) async => null;
}

/// Reads the grants only when a request needs them (building the routes
/// must not open the database).
class LazyOfferGrants implements OfferGrants {
  const new(this._get);

  final OfferGrants Function() _get;

  @override
  Future<SharedRoot?> inboxRoot(String clientFingerprint, String rootId) =>
      _get().inboxRoot(clientFingerprint, rootId);

  @override
  Future<bool> claim({
    required String offerId,
    required String clientFingerprint,
    required String name,
    required int size,
    required String uploadId,
  }) => _get().claim(
    offerId: offerId,
    clientFingerprint: clientFingerprint,
    name: name,
    size: size,
    uploadId: uploadId,
  );

  @override
  Future<void> completed(String uploadId, String finalId) =>
      _get().completed(uploadId, finalId);

  @override
  Future<void> released(String uploadId) => _get().released(uploadId);

  @override
  Future<String?> offeredFileId(String clientFingerprint, String fileId) =>
      _get().offeredFileId(clientFingerprint, fileId);
}

/// The receiver picked an excluded location for received files.
class OfferFolderRefused implements Exception {
  const new();
}

/// The answer of [OfferService.create]: an HTTP status with an offer, or
/// an error code.
typedef OfferCreateResult = ({
  int status,
  OfferDto? offer,
  ApiErrorCode? error,
});

/// What the receiver UI hears about (snackbars, notifications).
@immutable
sealed class OfferEvent {
  const new(this.offer);

  final ShareOffer offer;
}

/// A trusted sender's offer was accepted without a prompt.
final class OfferAutoAccepted extends OfferEvent {
  const new(super.offer);
}

/// Every file of an accepted incoming offer arrived.
final class OfferReceived extends OfferEvent {
  const new(super.offer);
}

/// One incoming offer waiting for the person holding this device.
@immutable
class OfferPrompt {
  const new({
    required this.offer,
    required this.platform,
    required this.remembered,
    required this.defaultFolder,
    this.words = const [],
  });

  final ShareOffer offer;

  /// The 4-word phrase both devices show (empty when unknown).
  final List<String> words;
  final String platform;

  /// A non-temporary remembered row exists for this key.
  final bool remembered;
  final String defaultFolder;
}

/// The receiving side of send files (TASK-N12): offers from clients, their
/// prompts, decisions and the upload grants they open. Offers persist in
/// `share_offers`; open ones are cached in memory. Accepted grants survive
/// stop sharing and restarts, so N10 resumes into them.
class OfferService implements OfferGrants {
  new({
    required this._repo,
    required this._devices,
    required this._sessions,
    required this._uploads,
    required this._freeBytes,
    required this.downloadsRoot,
    OfferLimiter? limiter,
    DateTime Function()? clock,
    this._serverFingerprint,
    this._prepareCopy,
    this._ownName,
    this._staging,
  }) : _clock = clock ?? DateTime.now,
       limiter = limiter ?? OfferLimiter(clock: clock);

  final OfferRepository _repo;
  final KnownDevicesRepository _devices;
  final ClientSessionStore Function() _sessions;
  final UploadStore _uploads;

  /// Free bytes on the volume of a path; null when unknown.
  final Future<int?> Function(String path) _freeBytes;

  /// Where received files go by default (`<root>/<sender>`).
  final String downloadsRoot;
  final OfferLimiter limiter;
  final DateTime Function() _clock;

  /// This device's key (for the 4-word phrase of a prompt).
  final Future<String> Function()? _serverFingerprint;

  /// N12b: a location-free copy of a file in `<staging>/offer-<id>/` when X2
  /// "Remove location" applies to it; null = offer the original.
  final Future<({String path, int sizeBytes})?> Function(
    FileRef f,
    String offerId,
    int seq,
  )?
  _prepareCopy;

  /// N12b: this device's name (the client's prompt).
  final Future<String> Function()? _ownName;

  /// N12b: where staged copies live (`offer-<id>/`).
  final Future<Directory> Function()? _staging;

  final Map<String, ShareOffer> _open = {};
  final Map<String, Timer> _timers = {};
  final Map<String, String> _uploadToOffer = {};

  /// Pairing details of a pending offer's sender (for "Remember").
  final Map<String, ({String deviceId, String platform})> _peers = {};
  final StreamController<OfferEvent> _events = StreamController.broadcast();
  final StreamController<List<OfferPrompt>> _prompts =
      StreamController.broadcast();
  List<OfferPrompt> _currentPrompts = const [];
  Future<void>? _loaded;
  bool _disposed = false;

  /// Receiver events (auto-accepted, received).
  Stream<OfferEvent> get events => _events.stream;

  /// Incoming offers waiting for a decision, oldest first.
  List<OfferPrompt> get prompts => _currentPrompts;
  Stream<List<OfferPrompt>> get promptChanges => _prompts.stream;

  /// The default folder for files from [peerName].
  String defaultFolderFor(String peerName) =>
      '$downloadsRoot/${safeFolderName(peerName)}';

  /// Loads open offers (once): expired pending ones and idle grants end,
  /// finished offers older than 30 days go.
  Future<void> start() => _loaded ??= _load();

  Future<void> _load() async {
    try {
      await _repo.purgeOld(now: _clock());
      final now = _clock();
      for (final o in await _repo.dao.open()) {
        if (!now.isBefore(o.expiresAt)) {
          await _end(o, OfferStatus.expired, notify: false);
          continue;
        }
        _cache(o);
        if (o.status == OfferStatus.pending) _schedule(o);
      }
      await _sweepStaged();
    } on Object catch (e, st) {
      developer.log(
        'offers not loaded',
        name: 'kfm.connect',
        error: e,
        stackTrace: st,
      );
    }
    await _publishPrompts();
  }

  void _cache(ShareOffer o) {
    if (o.isOpen) {
      _open[o.id] = o;
      for (final f in o.files) {
        if (f.uploadId case final u?) _uploadToOffer[u] = o.id;
      }
    } else {
      _open.remove(o.id);
      _timers.remove(o.id)?.cancel();
      _peers.remove(o.id);
      _uploadToOffer.removeWhere((_, id) => id == o.id);
    }
  }

  // ---- push: a client offers files ----

  /// `POST /v1/offers` (checks in the plan's order).
  Future<OfferCreateResult> create(
    ClientSession session,
    CreateOfferDto dto,
  ) async {
    await start();
    final fp = session.clientFingerprint;
    var existing = _open[dto.offerId] ?? await _repo.dao.byId(dto.offerId);
    if (existing != null) {
      existing = await _due(existing);
      // Another client's id is never revealed; a repeat is idempotent.
      if (existing.peerFingerprint != fp ||
          existing.direction != OfferDirection.incoming) {
        return (status: 404, offer: null, error: ApiErrorCode.notFound);
      }
      return (status: 200, offer: toDto(existing), error: null);
    }
    if (limiter.isLimited(fp)) {
      return (status: 429, offer: null, error: ApiErrorCode.tooManyAttempts);
    }
    final hasPending = _open.values.any(
      (o) =>
          o.direction == OfferDirection.incoming &&
          o.status == OfferStatus.pending &&
          o.peerFingerprint == fp,
    );
    if (hasPending || _currentPrompts.length >= kMaxQueuedOfferPrompts) {
      return (status: 409, offer: null, error: ApiErrorCode.busy);
    }
    var total = 0;
    for (final f in dto.files) {
      if (!isValidOfferName(f.name)) {
        return (status: 400, offer: null, error: ApiErrorCode.invalidName);
      }
      // No overflow: each size and the sum stay far below 2^62.
      if (f.size > (1 << 50) || total > (1 << 52)) {
        return (status: 413, offer: null, error: ApiErrorCode.tooLarge);
      }
      total += f.size;
    }
    limiter.recordOffer(fp);
    final now = _clock();
    var offer = ShareOffer(
      id: dto.offerId,
      direction: OfferDirection.incoming,
      peerFingerprint: fp,
      peerName: session.clientName,
      status: OfferStatus.pending,
      createdAt: now,
      expiresAt: now.add(kOfferDecisionTimeout),
      files: [
        for (final (i, f) in dto.files.indexed)
          ShareOfferFile(
            seq: i,
            name: f.name,
            sizeBytes: f.size,
            mimeType: f.mime,
          ),
      ],
    );
    int? free;
    try {
      free = await _freeBytes(downloadsRoot);
    } on Object {
      free = null;
    }
    if (free != null && free < total + kTransferSpaceMarginBytes) {
      offer = offer.copyWith(
        status: OfferStatus.declined,
        declineReason: OfferDeclineReason.noSpace.name,
        decidedAt: now,
      );
      await _repo.insert(offer);
      return (status: 201, offer: toDto(offer), error: null);
    }
    final known = await _devices.byFingerprint(fp);
    if (known != null && !known.isTemporary && known.autoAcceptFiles) {
      offer = offer.copyWith(
        status: OfferStatus.accepted,
        folder: defaultFolderFor(known.name),
        autoAccepted: true,
        decidedAt: now,
        expiresAt: now.add(kOfferGrantIdle),
      );
      await _repo.insert(offer);
      _cache(offer);
      limiter.recordAccept(fp);
      _emit(OfferAutoAccepted(offer));
      return (status: 201, offer: toDto(offer), error: null);
    }
    await _repo.insert(offer);
    _cache(offer);
    _peers[offer.id] = (
      deviceId: session.clientDeviceId,
      platform: known?.platform ?? '',
    );
    _schedule(offer);
    await _publishPrompts();
    return (status: 201, offer: toDto(offer), error: null);
  }

  /// `GET /v1/offers/<id>`: null (404) for another owner or an unknown id.
  Future<OfferDto?> status(String clientFingerprint, String offerId) async {
    await start();
    final o = _open[offerId] ?? await _repo.dao.byId(offerId);
    if (o == null ||
        o.peerFingerprint != clientFingerprint ||
        o.direction != OfferDirection.incoming) {
      return null;
    }
    return toDto(await _due(o));
  }

  /// A pending offer past its deadline expires now (the timer may not
  /// have run yet).
  Future<ShareOffer> _due(ShareOffer o) async {
    if (o.status != OfferStatus.pending || _clock().isBefore(o.expiresAt)) {
      return o;
    }
    _countExpiry(o);
    return await _end(o, OfferStatus.expired);
  }

  /// An unanswered incoming offer counts like a decline (spam cooldown).
  void _countExpiry(ShareOffer o) {
    if (o.direction == OfferDirection.incoming) {
      limiter.recordDecline(o.peerFingerprint);
    }
  }

  /// `DELETE /v1/offers/<id>`: the sender cancels (or ends a job with
  /// files it gave up on). Null (404) for another owner.
  Future<OfferDto?> cancelBySender(
    String clientFingerprint,
    String offerId,
  ) async {
    await start();
    final o = _open[offerId] ?? await _repo.dao.byId(offerId);
    if (o == null ||
        o.peerFingerprint != clientFingerprint ||
        o.direction != OfferDirection.incoming) {
      return null;
    }
    if (!o.isOpen) return toDto(o);
    final anyDone = o.files.any((f) => f.status == OfferFileStatus.done);
    final ended = await _end(
      o,
      anyDone ? OfferStatus.done : OfferStatus.cancelled,
    );
    return toDto(ended);
  }

  /// The receiver's answer to a prompt. [folder] (accept) must not be an
  /// excluded location ([OfferFolderRefused]). [remember] saves the sender as a
  /// remembered device; [alwaysAccept] also turns on "Accept files
  /// without asking". False when the offer is no longer pending.
  Future<bool> decide(
    String offerId, {
    required bool accept,
    String? folder,
    bool remember = false,
    bool alwaysAccept = false,
  }) async {
    await start();
    final current = _open[offerId];
    if (current == null) return false;
    final o = await _due(current);
    if (o.status != OfferStatus.pending) return false;
    final now = _clock();
    _timers.remove(offerId)?.cancel();
    if (!accept) {
      limiter.recordDecline(o.peerFingerprint);
      await _end(o, OfferStatus.declined, reason: OfferDeclineReason.user);
      return true;
    }
    final target = _trimSlash(folder ?? defaultFolderFor(o.peerName));
    if (PathGuard.isExcluded(target)) {
      _schedule(o);
      throw const OfferFolderRefused();
    }
    limiter.recordAccept(o.peerFingerprint);
    final accepted = o.copyWith(
      status: OfferStatus.accepted,
      folder: target,
      decidedAt: now,
      expiresAt: now.add(kOfferGrantIdle),
    );
    await _repo.save(accepted);
    _cache(accepted);
    final peer = _peers.remove(offerId);
    await _publishPrompts();
    if (remember || alwaysAccept) {
      await _devices.saveAfterPairing(
        PairedPeer(
          fingerprint: o.peerFingerprint,
          peerDeviceId: peer?.deviceId ?? '',
          name: o.peerName,
          platform: peer?.platform ?? '',
        ),
        temporary: false,
      );
      if (alwaysAccept) {
        await _devices.setAutoAcceptFiles(o.peerFingerprint, enabled: true);
      }
    }
    return true;
  }

  /// "Stop" on the receiver's card: the grant ends, running chunks are
  /// cancelled and the partials deleted. A pending offer is declined.
  Future<void> stopByReceiver(String offerId) async {
    await start();
    final o = _open[offerId];
    if (o == null) return;
    if (o.status == OfferStatus.pending) {
      _timers.remove(offerId)?.cancel();
      if (o.direction == OfferDirection.outgoing) {
        // N12b: the sharing device takes its own offer back.
        await _end(o, OfferStatus.cancelled);
      } else {
        await _end(o, OfferStatus.declined, reason: OfferDeclineReason.user);
      }
      return;
    }
    final anyDone = o.files.any((f) => f.status == OfferFileStatus.done);
    await _end(o, anyDone ? OfferStatus.done : OfferStatus.cancelled);
  }

  /// Stop sharing: pending offers expire (their prompts close); accepted
  /// grants stay for a later resume.
  Future<void> onStopSharing() async {
    for (final o in _open.values.toList()) {
      if (o.status == OfferStatus.pending) {
        await _end(o, OfferStatus.expired);
      }
    }
  }

  /// N6 remove / reset: every open offer of [fingerprint] ends.
  Future<void> revokeDevice(String fingerprint) async {
    await start();
    for (final o in _open.values.toList()) {
      if (o.peerFingerprint == fingerprint) {
        await _end(o, OfferStatus.cancelled);
      }
    }
  }

  /// Ends [offer] with [status]: timers, prompts, partials, streams.
  Future<ShareOffer> _end(
    ShareOffer offer,
    OfferStatus status, {
    OfferDeclineReason? reason,
    bool notify = true,
  }) async {
    // The cached copy is the newest (claims may have run meanwhile).
    final o = _open[offer.id] ?? offer;
    _timers.remove(o.id)?.cancel();
    final unfinished = [
      for (final f in o.files)
        if (!f.ended) f,
    ];
    final ended = o.copyWith(
      status: status,
      declineReason: reason?.name ?? o.declineReason,
      decidedAt: o.decidedAt ?? _clock(),
      files: [
        for (final f in o.files)
          if (f.ended) f else f.copyWith(status: OfferFileStatus.cancelled),
      ],
    );
    _cache(ended);
    // Saved before the slow cleanup below: [status] falls back to the row
    // once the offer left the cache, and a sender asking in between must
    // already read the end (not "accepted": its refused upload would
    // count as a permanent failure instead of "stopped by").
    await _repo.save(ended);
    for (final f in unfinished) {
      await _repo.saveFile(o.id, f.copyWith(status: OfferFileStatus.cancelled));
    }
    if (o.direction == OfferDirection.incoming &&
        o.status == OfferStatus.accepted) {
      final folder = o.folder;
      if (folder != null) {
        _sessions().cancelStreamsWhere(
          o.peerFingerprint,
          (path, {required write}) => path != folder,
        );
      }
      for (final f in unfinished) {
        if (f.uploadId case final u?) {
          try {
            await _uploads.remove(u);
          } on Object catch (e) {
            developer.log('offer partial not removed: $e', name: 'kfm.connect');
          }
        }
      }
    }
    if (o.direction == OfferDirection.outgoing) {
      // N12b: the client's inbox changed; staged copies go.
      _bumpInbox(o.peerFingerprint);
      await _deleteStaged(o.id);
    }
    if (notify) await _publishPrompts();
    return ended;
  }

  Future<void> _deleteStaged(String offerId) async {
    final staging = _staging;
    if (staging == null) return;
    try {
      final dir = Directory('${(await staging()).path}/offer-$offerId');
      if (await dir.exists()) await dir.delete(recursive: true);
    } on Object catch (e) {
      developer.log('staged copies not deleted: $e', name: 'kfm.connect');
    }
  }

  /// Start: staged copies of offers that are no longer open go.
  Future<void> _sweepStaged() async {
    final staging = _staging;
    if (staging == null) return;
    try {
      final dir = await staging();
      if (!await dir.exists()) return;
      await for (final e in dir.list()) {
        final name = e.uri.pathSegments.where((x) => x.isNotEmpty).last;
        if (e is! Directory || !name.startsWith('offer-')) continue;
        if (!_open.containsKey(name.substring('offer-'.length))) {
          await e.delete(recursive: true);
        }
      }
    } on Object catch (e) {
      developer.log('staged copies not swept: $e', name: 'kfm.connect');
    }
  }

  void _schedule(ShareOffer o) {
    _timers.remove(o.id)?.cancel();
    final left = o.expiresAt.difference(_clock());
    _timers[o.id] = Timer(left.isNegative ? Duration.zero : left, () {
      _timers.remove(o.id);
      final now = _open[o.id];
      if (now != null && now.status == OfferStatus.pending) {
        _countExpiry(now);
        unawaited(_end(now, OfferStatus.expired));
      }
    });
  }

  Future<void> _publishPrompts() async {
    final pending = [
      for (final o in _open.values)
        if (o.direction == OfferDirection.incoming &&
            o.status == OfferStatus.pending)
          o,
    ]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final out = <OfferPrompt>[];
    String? serverFp;
    try {
      serverFp = await _serverFingerprint?.call();
    } on Object {
      serverFp = null;
    }
    for (final o in pending) {
      KnownDevice? known;
      try {
        known = await _devices.byFingerprint(o.peerFingerprint);
      } on Object {
        known = null;
      }
      out.add(
        OfferPrompt(
          offer: o,
          platform: _peers[o.id]?.platform ?? known?.platform ?? '',
          remembered: known != null && !known.isTemporary,
          defaultFolder: defaultFolderFor(o.peerName),
          words: serverFp == null
              ? const []
              : fingerprintWords(serverFp, o.peerFingerprint),
        ),
      );
    }
    if (_disposed) return;
    _currentPrompts = List.unmodifiable(out);
    _prompts.add(_currentPrompts);
  }

  // ---- grants (OfferGrants) ----

  /// Activity extends a grant by [kOfferGrantIdle], but never past
  /// [kOfferGrantMaxAge] after it was accepted.
  DateTime _extended(ShareOffer o) {
    final idle = _clock().add(kOfferGrantIdle);
    final cap = (o.decidedAt ?? _clock()).add(kOfferGrantMaxAge);
    return idle.isBefore(cap) ? idle : cap;
  }

  Future<ShareOffer?> _grant(String clientFingerprint, String offerId) async {
    final o = _open[offerId];
    if (o == null ||
        o.direction != OfferDirection.incoming ||
        o.status != OfferStatus.accepted ||
        o.peerFingerprint != clientFingerprint ||
        o.folder == null) {
      return null;
    }
    final cap = (o.decidedAt ?? o.createdAt).add(kOfferGrantMaxAge);
    if (!_clock().isBefore(o.expiresAt) || !_clock().isBefore(cap)) {
      await _end(o, OfferStatus.expired);
      return null;
    }
    return o;
  }

  @override
  Future<SharedRoot?> inboxRoot(String clientFingerprint, String rootId) async {
    await start();
    final id = offerIdOfRoot(rootId);
    if (id == null) return null;
    final o = await _grant(clientFingerprint, id);
    final folder = o?.folder;
    if (o == null || folder == null) return null;
    return SharedRoot(
      id: rootId,
      path: folder,
      label: folder.split('/').last,
      readOnly: false,
    );
  }

  /// Claims run one at a time (two files of an offer upload at once).
  Future<void> _claims = Future<void>.value();

  @override
  Future<bool> claim({
    required String offerId,
    required String clientFingerprint,
    required String name,
    required int size,
    required String uploadId,
  }) {
    final run = _claims.then(
      (_) => _claim(
        offerId: offerId,
        clientFingerprint: clientFingerprint,
        name: name,
        size: size,
        uploadId: uploadId,
      ),
    );
    _claims = run.then<void>((_) {}, onError: (Object _) {});
    return run;
  }

  Future<bool> _claim({
    required String offerId,
    required String clientFingerprint,
    required String name,
    required int size,
    required String uploadId,
  }) async {
    await start();
    final o = await _grant(clientFingerprint, offerId);
    if (o == null) return false;
    // A repeated create of the SAME upload (lost answer) passes only for
    // that exact file while it transfers; a finished file's id never opens
    // another upload.
    final mine = o.files.where((f) => f.uploadId == uploadId).firstOrNull;
    if (mine != null) {
      return mine.status == OfferFileStatus.transferring &&
          mine.name == name &&
          size >= 0 &&
          size <= mine.sizeBytes + kOfferSizeSlackBytes;
    }
    // Claims whose upload is gone (verification failed, dropped partial)
    // may be taken again by the sender's retry.
    final stale = <int>{};
    for (final c in o.files) {
      if (c.status == OfferFileStatus.transferring &&
          c.uploadId != null &&
          await _uploads.any(c.uploadId!) == null) {
        stale.add(c.seq);
      }
    }
    // From here on synchronous: the cache may have changed while waiting.
    final cur = _open[offerId];
    if (cur == null || cur.status != OfferStatus.accepted) return false;
    final f = cur.files
        .where(
          (c) =>
              c.name == name &&
              size >= 0 &&
              size <= c.sizeBytes + kOfferSizeSlackBytes &&
              ((c.status == OfferFileStatus.waiting && c.uploadId == null) ||
                  stale.contains(c.seq)),
        )
        .firstOrNull;
    if (f == null) return false;
    if (f.uploadId case final old?) _uploadToOffer.remove(old);
    final claimed = f.copyWith(
      uploadId: uploadId,
      status: OfferFileStatus.transferring,
    );
    final next = cur.withFile(claimed).copyWith(expiresAt: _extended(cur));
    _cache(next);
    await _repo.saveFile(offerId, claimed);
    await _repo.save(next);
    return true;
  }

  @override
  Future<void> completed(String uploadId, String finalId) async {
    // Synchronous read-modify-write of the cache (uploads finish at once).
    final o = _open[_uploadToOffer[uploadId] ?? ''];
    if (o == null) return;
    final f = o.files.where((f) => f.uploadId == uploadId).firstOrNull;
    if (f == null) return;
    final done = f.copyWith(status: OfferFileStatus.done, localFileId: finalId);
    var next = o.withFile(done).copyWith(expiresAt: _extended(o));
    final finished = next.allFilesEnded;
    if (finished) next = next.copyWith(status: OfferStatus.done);
    _cache(next);
    await _repo.saveFile(o.id, done);
    await _repo.save(next);
    if (finished) _emit(OfferReceived(next));
  }

  @override
  Future<void> released(String uploadId) async {
    final offerId = _uploadToOffer.remove(uploadId);
    final o = _open[offerId ?? ''];
    if (o == null) return;
    final f = o.files.where((f) => f.uploadId == uploadId).firstOrNull;
    if (f == null || f.ended) return;
    final back = f.copyWith(uploadId: null, status: OfferFileStatus.waiting);
    _cache(o.withFile(back));
    await _repo.saveFile(o.id, back);
  }

  // ---- N12b: offers this device makes to a connected client ----

  /// The N12b "Send to…" on a sharing device: offers [files] to the
  /// connected client [clientFingerprint]. With X2 "Remove location" on,
  /// photos and videos are prepared into `<staging>/offer-<id>/` first
  /// (`prepareCopy`); the offer lists the prepared sizes and grants reads
  /// of exactly those paths. Returns the offer.
  Future<ShareOffer> offerToClient(
    String clientFingerprint,
    String clientName,
    List<FileRef> files,
  ) async {
    await start();
    final id = randomHexId();
    final now = _clock();
    final out = <ShareOfferFile>[];
    for (final (i, f) in files.indexed) {
      final staged = await _prepareCopy?.call(f, id, i);
      if (staged != null) {
        out.add(
          ShareOfferFile(
            seq: i,
            name: f.name,
            sizeBytes: staged.sizeBytes,
            mimeType: f.mimeType,
            localFileId: 'path:${staged.path}',
            canonicalPath: staged.path,
            sourceModifiedAtMs: f.modifiedAt.millisecondsSinceEpoch,
          ),
        );
        continue;
      }
      out.add(
        ShareOfferFile(
          seq: i,
          name: f.name,
          sizeBytes: f.sizeBytes,
          mimeType: f.mimeType,
          localFileId: f.id,
          sourceModifiedAtMs: f.modifiedAt.millisecondsSinceEpoch,
        ),
      );
    }
    final known = await _devices.byFingerprint(clientFingerprint);
    final offer = ShareOffer(
      id: id,
      direction: OfferDirection.outgoing,
      peerFingerprint: clientFingerprint,
      peerName: known?.name ?? clientName,
      status: OfferStatus.pending,
      createdAt: now,
      expiresAt: now.add(kOfferDecisionTimeout),
      files: out,
    );
    await _repo.insert(offer);
    _cache(offer);
    _schedule(offer);
    _bumpInbox(clientFingerprint);
    return offer;
  }

  final Map<String, int> _inboxVersion = {};

  /// Changes whenever [clientFingerprint]'s inbox changes (heartbeat).
  String inboxTokenFor(String clientFingerprint) =>
      '${_inboxVersion[clientFingerprint] ?? 0}';

  void _bumpInbox(String fp) =>
      _inboxVersion[fp] = (_inboxVersion[fp] ?? 0) + 1;

  /// `GET /v1/inbox`: pending offers made to [clientFingerprint].
  Future<List<OfferDto>> inboxFor(String clientFingerprint) async {
    await start();
    final out = <OfferDto>[];
    for (final o in _open.values.toList()) {
      if (o.direction != OfferDirection.outgoing ||
          o.peerFingerprint != clientFingerprint) {
        continue;
      }
      final cur = await _due(o);
      if (cur.status != OfferStatus.pending) continue;
      final dto = toDto(cur);
      out.add(
        OfferDto(
          id: dto.id,
          status: dto.status,
          expiresInSeconds: dto.expiresInSeconds,
          senderName: await _ownName?.call() ?? '',
          files: [
            for (final f in cur.files)
              OfferFileDto(
                name: f.name,
                size: f.sizeBytes,
                mime: f.mimeType,
                // Opaque: no local path or MediaStore id leaves.
                id: offeredId(cur.id, f.seq),
                modifiedAtMs: f.sourceModifiedAtMs,
              ),
          ],
        ),
      );
    }
    return out;
  }

  /// The client's answer to an offer made to it. False (404) for another
  /// client's or an ended offer.
  Future<bool> decideOutgoing(
    String clientFingerprint,
    String offerId, {
    required bool accept,
  }) async {
    await start();
    final current = _open[offerId];
    if (current == null ||
        current.direction != OfferDirection.outgoing ||
        current.peerFingerprint != clientFingerprint) {
      return false;
    }
    final o = await _due(current);
    if (o.status != OfferStatus.pending) return false;
    _timers.remove(offerId)?.cancel();
    if (!accept) {
      await _end(o, OfferStatus.declined, reason: OfferDeclineReason.user);
      _bumpInbox(clientFingerprint);
      return true;
    }
    final now = _clock();
    final accepted = o.copyWith(
      status: OfferStatus.accepted,
      decidedAt: now,
      expiresAt: now.add(kOfferGrantIdle),
    );
    _cache(accepted);
    await _repo.save(accepted);
    _bumpInbox(clientFingerprint);
    return true;
  }

  /// `POST /v1/inbox/<id>/finished`: the grant ends; staged copies go.
  Future<bool> finishedOutgoing(
    String clientFingerprint,
    String offerId,
    InboxFinishedDto report,
  ) async {
    await start();
    final o = _open[offerId];
    if (o == null ||
        o.direction != OfferDirection.outgoing ||
        o.peerFingerprint != clientFingerprint) {
      return false;
    }
    final next = o.copyWith(
      files: [
        for (final f in o.files)
          if (report.done.contains(f.seq))
            f.copyWith(status: OfferFileStatus.done)
          else if (report.failed.contains(f.seq))
            f.copyWith(status: OfferFileStatus.failed)
          else
            f,
      ],
    );
    _cache(next);
    for (final f in next.files) {
      if (f.ended) await _repo.saveFile(o.id, f);
    }
    await _end(
      next,
      next.files.any((f) => f.status == OfferFileStatus.done)
          ? OfferStatus.done
          : OfferStatus.failed,
    );
    return true;
  }

  /// The opaque id a client downloads offered file [seq] of [offerId] by.
  static String offeredId(String offerId, int seq) => 'offered-$offerId-$seq';

  static final RegExp _offeredId = RegExp(
    r'^offered-([0-9a-f]{32})-(\d{1,4})$',
  );

  @override
  Future<String?> offeredFileId(String clientFingerprint, String fileId) async {
    final m = _offeredId.firstMatch(fileId);
    if (m == null) return null;
    await start();
    final o = _open[m.group(1)!];
    if (o == null ||
        o.direction != OfferDirection.outgoing ||
        o.status != OfferStatus.accepted ||
        o.peerFingerprint != clientFingerprint ||
        !_clock().isBefore(o.expiresAt)) {
      return null;
    }
    final seq = int.parse(m.group(2)!);
    final f = o.files.where((f) => f.seq == seq).firstOrNull;
    if (f == null || f.ended) return null;
    return f.localFileId;
  }

  /// The wire view of [o].
  OfferDto toDto(ShareOffer o) {
    final now = _clock();
    return OfferDto(
      id: o.id,
      status: switch (o.status) {
        OfferStatus.pending => OfferWireStatus.pending,
        OfferStatus.accepted => OfferWireStatus.accepted,
        OfferStatus.declined => OfferWireStatus.declined,
        OfferStatus.expired => OfferWireStatus.expired,
        OfferStatus.cancelled ||
        OfferStatus.failed => OfferWireStatus.cancelled,
        OfferStatus.done => OfferWireStatus.done,
      },
      reason: OfferDeclineReason.fromWire(o.declineReason),
      expiresInSeconds: o.status == OfferStatus.pending
          ? o.expiresAt.difference(now).inSeconds.clamp(0, 1 << 20)
          : null,
      rootId: o.status == OfferStatus.accepted ? offerRootId(o.id) : null,
    );
  }

  @visibleForTesting
  ShareOffer? openOffer(String id) => _open[id];

  /// A fresh offer id (N12b offers made here).
  static String newOfferId() => randomHexId();

  void _emit(OfferEvent e) {
    if (!_disposed) _events.add(e);
  }

  void dispose() {
    _disposed = true;
    for (final t in _timers.values) {
      t.cancel();
    }
    _timers.clear();
    unawaited(_events.close());
    unawaited(_prompts.close());
  }
}

String _trimSlash(String p) =>
    p.length > 1 && p.endsWith('/') ? p.substring(0, p.length - 1) : p;
