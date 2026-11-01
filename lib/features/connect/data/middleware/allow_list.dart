import 'dart:convert';
import 'dart:developer' as developer;

import 'package:kfm/core/files/file_source.dart';
import 'package:kfm/features/connect/data/middleware/authenticate.dart';
import 'package:kfm/features/connect/data/path_guard.dart';
import 'package:kfm/features/connect/data/server_pipeline.dart';
import 'package:kfm/features/connect/domain/protocol.dart';
import 'package:kfm/features/connect/domain/share_scope.dart';
import 'package:meta/meta.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

/// One id or path a request touches (TASK-N4).
@immutable
sealed class GuardTarget {
  const new({this.write = false});

  /// True: the request changes something there (move/rename/trash/upload).
  final bool write;
}

/// A file by its server id (`path:` / `ms:`).
final class FileIdTarget extends GuardTarget {
  const new(this.id, {super.write});

  final String id;
}

/// A folder or file by shared root + relative path (listings, upload and
/// move targets).
final class RootPathTarget extends GuardTarget {
  const new(this.rootId, this.relativePath, {super.write});

  final String rootId;
  final String relativePath;
}

/// A target that passed the guard, in request order. Route bodies use
/// these instead of re-reading ids or paths from the request.
@immutable
class ResolvedTarget {
  const new({
    required this.target,
    required this.canonicalPath,
    required this.root,
    this.file,
  });

  final GuardTarget target;
  final String canonicalPath;
  final SharedRoot root;

  /// Set for a [FileIdTarget].
  final GuardedFile? file;
}

/// What `extract` gets: the request plus its JSON body (read once, then
/// handed on to the route as a fresh body).
class GuardInput {
  new(this.request);

  final Request request;
  List<int>? _bytes;
  Map<String, Object?>? _json;

  /// The JSON object body; throws [FormatException] when it isn't one.
  Future<Map<String, Object?>> json() async {
    if (_json case final j?) return j;
    if (_bytes == null) {
      final all = <int>[];
      await for (final chunk in request.read()) {
        all.addAll(chunk);
        // Also on size-limit-exempt routes (N10 chunks).
        if (all.length > kMaxJsonBodyBytes) {
          throw const FormatException('body too large');
        }
      }
      _bytes = all;
    }
    final decoded = jsonDecode(utf8.decode(_bytes!));
    if (decoded is! Map<String, Object?>) {
      throw const FormatException('body is not a JSON object');
    }
    return _json = decoded;
  }

  Request forward() => _bytes == null ? request : request.change(body: _bytes);
}

/// The shelf_router path parameter [name], percent-decoded once
/// (shelf_router hands it over still encoded, so a `path:` id arrives as
/// `path%3A%2F…`). Bad encoding throws [FormatException] (→ 403 in
/// `guarded`). File routes extract ids with this, never by hand.
String routeParam(Request request, String name) {
  final raw = request.params[name];
  if (raw == null) throw FormatException('missing route parameter $name');
  // Every '%' must start a hex pair (decodeComponent throws an Error
  // otherwise); bad UTF-8 throws FormatException itself.
  if (_badPercent.hasMatch(raw)) {
    throw FormatException('bad encoding in $name');
  }
  return Uri.decodeComponent(raw);
}

final RegExp _badPercent = RegExp('%(?![0-9A-Fa-f]{2})');

const String _kGuardContextKey = 'kfm.guard';

/// The targets the guard resolved for [request] (empty outside `guarded`).
List<ResolvedTarget> guardedTargetsOf(Request request) {
  final t = request.context[_kGuardContextKey];
  return t is List<ResolvedTarget> ? t : const [];
}

/// Handlers produced by [AllowListGuard.guarded]; the route-coverage check
/// reads this.
final Expando<bool> _guardedHandlers = Expando('guarded');

bool isGuardedHandler(Handler h) => _guardedHandlers[h] ?? false;

/// Every route that is neither unauthenticated, nor in
/// [kNoFileAccessRoutes], nor wrapped in `guarded(...)`. Must be empty
/// (route-coverage test).
List<ServerRoute> unguardedRoutes(Iterable<ServerRoute> routes) => [
  for (final r in routes)
    if (!kUnauthenticatedRoutes.contains(r.key) &&
        !kNoFileAccessRoutes.contains(r.key) &&
        !isGuardedHandler(r.handler))
      r,
];

/// The folder allow-list, enforced per route on the server (TASK-N4). A
/// global middleware can't see route parameters or bodies, so every file
/// and upload route wraps its handler with [guarded].
class AllowListGuard {
  new({required this.scopeOf, required this.source, required this.paths});

  /// The client's scope by fingerprint (read per request: edits apply to
  /// the next request).
  final ShareScope Function(String clientFingerprint) scopeOf;
  final FileSource Function() source;
  final PathGuard paths;

  /// Wraps [inner]: every target [extract] returns must be inside the
  /// session's scope, outside the excluded locations, and (when written:
  /// [write] or the target's own flag) under a writable root. Otherwise
  /// 403 `forbidden_path` (404 only for an unknown file id inside the
  /// scope). Move/copy return both source and destination, so both are
  /// checked; a move or trash *source* is a write target too. An empty
  /// target list is refused unless [allowEmpty]. Route bodies read ids and
  /// paths only from [guardedTargetsOf], never from the request again.
  Handler guarded(
    Handler inner, {
    required Future<List<GuardTarget>> Function(GuardInput input) extract,
    required bool write,
    bool allowEmpty = false,
  }) {
    Future<Response> handler(Request request) async {
      final session = sessionOf(request);
      if (session == null) return apiError(ApiErrorCode.unauthorized);
      final scope = scopeOf(session.clientFingerprint);
      final input = GuardInput(request);
      final resolved = <ResolvedTarget>[];
      try {
        final targets = await extract(input);
        // A wrapper that checks nothing is a missing guard.
        if (targets.isEmpty && !allowEmpty) {
          return apiError(ApiErrorCode.forbiddenPath);
        }
        for (final t in targets) {
          resolved.add(await _check(scope, t, write: write || t.write));
        }
      } on GuardRejection catch (e) {
        return apiError(e.code);
      } on Object catch (e) {
        // Bad body or field types, realpath or MediaStore failures: deny,
        // never a 500 that differs from the 403 answer.
        developer.log(
          'allow-list: ${request.method} ${request.requestedUri.path} '
          'denied: ${e.runtimeType}',
          name: 'kfm.connect',
        );
        return apiError(ApiErrorCode.forbiddenPath);
      }
      return await inner(
        input.forward().change(context: {_kGuardContextKey: resolved}),
      );
    }

    _guardedHandlers[handler] = true;
    return handler;
  }

  Future<ResolvedTarget> _check(
    ShareScope scope,
    GuardTarget target, {
    required bool write,
  }) async {
    final String canonical;
    GuardedFile? file;
    switch (target) {
      case FileIdTarget(:final id):
        file = await paths.resolveFileId(
          id,
          source(),
          inScope: (path) => _inScope(scope, path, write: write),
        );
        canonical = file.canonicalPath;
      case RootPathTarget(:final rootId, :final relativePath):
        final named = scope.byId(rootId);
        if (named == null) {
          throw const GuardRejection(ApiErrorCode.forbiddenPath, 'root');
        }
        canonical = await paths.joinRelative(named, relativePath);
    }
    final root = _inScope(scope, canonical, write: write);
    return ResolvedTarget(
      target: target,
      canonicalPath: canonical,
      root: root,
      file: file,
    );
  }

  static SharedRoot _inScope(
    ShareScope scope,
    String path, {
    required bool write,
  }) {
    if (PathGuard.isExcluded(path)) {
      throw const GuardRejection(ApiErrorCode.forbiddenPath, 'excluded');
    }
    final root = scope.rootFor(path);
    if (root == null) {
      throw const GuardRejection(ApiErrorCode.forbiddenPath, 'outside');
    }
    if (write && root.readOnly) {
      throw const GuardRejection(ApiErrorCode.forbiddenPath, 'read-only');
    }
    return root;
  }
}
