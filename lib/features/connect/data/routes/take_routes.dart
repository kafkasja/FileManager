import 'package:kfm/features/connect/data/middleware/allow_list.dart';
import 'package:kfm/features/connect/data/middleware/authenticate.dart';
import 'package:kfm/features/connect/data/server_pipeline.dart';
import 'package:kfm/features/connect/data/take_gate.dart';
import 'package:kfm/features/connect/domain/link.dart';
import 'package:kfm/features/connect/domain/protocol.dart';

/// TASK-E1 `POST /v1/take {ids, move}`: a linked peer asks before it reads
/// files in full (a download job, a video). Guarded like every file route
/// (ids outside the scope → 403/404 before anyone is asked). Take-free
/// peers get `{granted: true}` at once; otherwise the owner's prompt
/// decides while the request is held (≤ [kTakeDecisionTimeout]): 200
/// granted, 403 `declined` / `timed_out`, 409 `busy` (too many waiting).
ServerRoute takeRoute({
  required AllowListGuard guard,
  required TakeGate gate,
}) => ServerRoute(
  'POST',
  ApiRoutes.take,
  guard.guarded(
    (request) async {
      final session = sessionOf(request);
      if (session == null) return apiError(ApiErrorCode.unauthorized);
      final targets = guardedTargetsOf(request);
      final body = TakeRequestDto.fromJson(await GuardInput(request).json());
      final fp = session.clientFingerprint;
      if (!gate.needsApproval(fp)) return jsonOk({'granted': true});
      final decision = await gate.request(
        peerFingerprint: fp,
        peerName: session.clientName,
        ids: [for (final t in targets) (t.target as FileIdTarget).id],
        files: [
          for (final t in targets)
            if (t.file case final f?)
              TakeFile(
                name: f.ref.name,
                sizeBytes: f.ref.sizeBytes,
                mimeType: f.ref.mimeType,
              ),
        ],
        move: body.move,
      );
      return switch (decision) {
        TakeDecision.allowed => jsonOk({'granted': true}),
        TakeDecision.declined => apiError(ApiErrorCode.declined),
        TakeDecision.timedOut => apiError(ApiErrorCode.timedOut),
        TakeDecision.busy => apiError(ApiErrorCode.busy),
      };
    },
    write: false,
    extract: (i) async {
      final body = TakeRequestDto.fromJson(await i.json());
      if (body.ids.length > kMaxTakeIds) {
        throw const FormatException('too many ids');
      }
      return [
        for (final id in {...body.ids}) FileIdTarget(id),
      ];
    },
  ),
);
