import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/features/connect/data/connect_providers.dart';
import 'package:kfm/features/connect/data/middleware/allow_list.dart';
import 'package:kfm/features/connect/data/secret_store.dart';
import 'package:kfm/features/connect/data/server_pipeline.dart';
import 'package:kfm/features/connect/domain/protocol.dart';
import 'package:shelf/shelf.dart';

/// TASK-N4: every route the share server registers is unauthenticated (N1
/// allow-set), explicitly file-free, or wrapped in `guarded(...)`.
void main() {
  test('every registered share route is guarded or explicitly exempt', () {
    final container = ProviderContainer(
      overrides: [secretStoreProvider.overrideWithValue(InMemorySecretStore())],
    );
    addTearDown(container.dispose);
    final routes = container.read(shareServerRoutesProvider);
    expect(routes, isNotEmpty);
    expect(
      unguardedRoutes(routes).map((r) => r.key),
      isEmpty,
      reason: 'wrap file routes in AllowListGuard.guarded',
    );
    expect(
      routes.map((r) => r.key),
      contains(routeKey('GET', ApiRoutes.roots)),
    );
  });

  test('the check catches a file route without the guard', () {
    final container = ProviderContainer(
      overrides: [secretStoreProvider.overrideWithValue(InMemorySecretStore())],
    );
    addTearDown(container.dispose);
    final guard = container.read(allowListGuardProvider);
    Response inner(Request _) => Response.ok('');
    final bare = ServerRoute('GET', '/v1/files/<id>/content', inner);
    final wrapped = ServerRoute(
      'GET',
      '/v1/files/<id>/content',
      guard.guarded(inner, write: false, extract: (_) async => const []),
    );
    expect(unguardedRoutes([bare]), [bare]);
    expect(unguardedRoutes([wrapped]), isEmpty);
    expect(
      unguardedRoutes([ServerRoute('GET', ApiRoutes.roots, inner)]),
      isEmpty,
    );
  });
}
