import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/core/db/settings/settings_repository.dart';
import 'package:kfm/desktop/shell/desktop_location.dart';
import 'package:kfm/desktop/shell/desktop_shell_state.dart';
import 'package:kfm/desktop/tabs/desktop_tabs_controller.dart';

void main() {
  late AppDatabase db;
  late DbWriteQueue queue;
  late SettingsRepository settings;
  late ProviderContainer c;

  ProviderContainer container({Set<String> existing = const {}}) =>
      ProviderContainer(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(settings),
          desktopFolderExistsProvider.overrideWithValue(
            (p) async => existing.contains(p),
          ),
        ],
      );

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    queue = DbWriteQueue();
    settings = SettingsRepository(db, queue);
    c = container()..listen(desktopTabsControllerProvider, (_, _) {});
    // Most tests start from one Home tab (what a closed window gives).
    c
        .read(desktopTabsControllerProvider.notifier)
        .replace(const HomeLocation());
  });
  tearDown(() async {
    c.dispose();
    await queue.close();
    await db.close();
  });

  DesktopTabsController ctl() => c.read(desktopTabsControllerProvider.notifier);
  DesktopTabsState st() => c.read(desktopTabsControllerProvider);
  List<DesktopLocation> locs() => [for (final t in st().tabs) t.location];

  test('a fresh install starts with one Sort tab', () {
    c.dispose();
    c = container()..listen(desktopTabsControllerProvider, (_, _) {});
    expect(locs(), [const SortLocation()]);
    expect(st().active, 0);
  });

  test('navigate, back, forward and up stay in the active tab', () {
    ctl()
      ..navigate(const FolderLocation('C:/Users/k'))
      ..navigate(const FolderLocation('C:/Users/k/Pictures'));
    expect(st().current.location, const FolderLocation('C:/Users/k/Pictures'));
    ctl().back();
    expect(st().current.location, const FolderLocation('C:/Users/k'));
    ctl().forward();
    expect(st().current.location, const FolderLocation('C:/Users/k/Pictures'));
    ctl().up();
    expect(st().current.location, const FolderLocation('C:/Users/k'));
    expect(st().current.forward, isEmpty);
    ctl()
      ..navigate(const FolderLocation('C:'))
      ..up();
    expect(st().current.location, const HomeLocation());
    expect(st().tabs, hasLength(1));
  });

  test('folder paths compare without case', () {
    ctl().navigate(const FolderLocation('C:/Users'));
    ctl().navigate(const FolderLocation('c:/users'));
    expect(st().current.back, [const HomeLocation()]);
  });

  test('new tabs open after the active one; closing the last leaves Home', () {
    ctl()
      ..navigate(const FolderLocation('C:/a'))
      ..openInNewTab(const FolderLocation('C:/b'))
      ..activate(0)
      ..openInNewTab(const FolderLocation('C:/c'));
    expect(locs(), const [
      FolderLocation('C:/a'),
      FolderLocation('C:/c'),
      FolderLocation('C:/b'),
    ]);
    expect(st().active, 1);
    for (final t in [...st().tabs]) {
      ctl().close(t.id);
    }
    expect(locs(), [const HomeLocation()]);
  });

  test('closing the active tab activates its neighbour', () {
    ctl()
      ..openInNewTab(const FolderLocation('C:/b'))
      ..openInNewTab(const FolderLocation('C:/c'));
    expect(st().active, 2);
    ctl().close(st().current.id);
    expect(st().current.location, const FolderLocation('C:/b'));
    ctl().activate(0);
    ctl().close(st().tabs[1].id);
    expect(st().active, 0);
  });

  test('Sort, Trash, Devices and Settings never open twice', () {
    ctl()
      ..openInNewTab(const SortLocation())
      ..openInNewTab(const FolderLocation('C:/x'))
      ..openInNewTab(const SortLocation());
    expect(locs().whereType<SortLocation>(), hasLength(1));
    expect(st().current.location, const SortLocation());
    ctl()
      ..activate(0)
      ..navigate(const SortLocation());
    expect(locs().whereType<SortLocation>(), hasLength(1));
    expect(st().active, 1);
    expect(const SortLocation().section, DesktopSection.sort);
    expect(const TrashLocation().singleInstance, isTrue);
  });

  test('move keeps the active tab active', () {
    ctl()
      ..openInNewTab(const FolderLocation('C:/b'))
      ..openInNewTab(const FolderLocation('C:/c'))
      ..activate(1)
      ..move(1, 2);
    expect(locs(), const [
      HomeLocation(),
      FolderLocation('C:/c'),
      FolderLocation('C:/b'),
    ]);
    expect(st().current.location, const FolderLocation('C:/b'));
    ctl().move(2, 0);
    expect(st().active, 0);
  });

  test('reopen closed brings tabs back in reverse order, max 10', () {
    ctl()
      ..openInNewTab(const FolderLocation('C:/b'))
      ..openInNewTab(const FolderLocation('C:/c'));
    ctl().close(st().tabs[1].id);
    ctl().close(st().tabs[1].id);
    expect(locs(), [const HomeLocation()]);
    ctl().reopenClosed();
    expect(locs(), const [HomeLocation(), FolderLocation('C:/c')]);
    ctl().reopenClosed();
    expect(locs(), const [
      HomeLocation(),
      FolderLocation('C:/b'),
      FolderLocation('C:/c'),
    ]);
    expect(ctl().canReopen, isFalse);
    for (var i = 0; i < 15; i++) {
      ctl().openInNewTab(FolderLocation('C:/n$i'));
      ctl().close(st().current.id);
    }
    var n = 0;
    while (ctl().canReopen) {
      ctl().reopenClosed();
      n++;
    }
    expect(n, DesktopTabsController.maxClosed);
  });

  test('closing the last tab and reopening replaces the lone Home', () {
    ctl().navigate(const FolderLocation('C:/a'));
    ctl().close(st().current.id);
    ctl().reopenClosed();
    expect(locs(), const [FolderLocation('C:/a')]);
  });

  test('close others / to the right', () {
    ctl()
      ..openInNewTab(const FolderLocation('C:/b'))
      ..openInNewTab(const FolderLocation('C:/c'))
      ..openInNewTab(const FolderLocation('C:/d'))
      ..closeToTheRight(1);
    expect(locs(), const [HomeLocation(), FolderLocation('C:/b')]);
    ctl().closeOthers(1);
    expect(locs(), const [FolderLocation('C:/b')]);
  });

  test('JSON round trip of every location', () {
    const all = <DesktopLocation>[
      HomeLocation(),
      FolderLocation('C:/Users/k/Pictures'),
      SearchLocation('cat', scope: 'C:/x'),
      SearchLocation('dog'),
      SortLocation(),
      TrashLocation(),
      DevicesLocation(),
      SettingsLocation(),
      RouteLocation('/browse/collections'),
    ];
    for (final l in all) {
      expect(DesktopLocation.fromJson(l.toJson()), l);
    }
    expect(DesktopLocation.fromJson(const {'k': 'nope'}), const HomeLocation());
    expect(
      DesktopLocation.fromJson(const {'k': 'folder'}),
      const HomeLocation(),
    );
    expect(
      const RouteLocation('/browse/collections').section,
      DesktopSection.browse,
    );
  });

  test(
    'restores tabs and the active one; a gone folder becomes Home',
    () async {
      await settings.write(
        AppSettings.desktopTabs,
        DesktopTabsController.encode(
          const DesktopTabsState(
            tabs: [
              DesktopTab(id: 'a', location: FolderLocation('C:/kept')),
              DesktopTab(id: 'b', location: FolderLocation('C:/gone')),
              DesktopTab(id: 'c', location: SortLocation()),
            ],
            active: 2,
          ),
        ),
      );
      c.dispose();
      c = container(existing: {'C:/kept'})
        ..listen(desktopTabsControllerProvider, (_, _) {});
      await ctl().restored.future;
      expect(locs(), const [
        FolderLocation('C:/kept'),
        HomeLocation(),
        SortLocation(),
      ]);
      expect(st().active, 2);
    },
  );

  test('changes are saved (debounced) and survive a new container', () async {
    await ctl().restored.future;
    ctl()
      ..navigate(const FolderLocation('C:/a'))
      ..openInNewTab(const TrashLocation());
    ctl().flush();
    await queue.flush();
    c.dispose();
    c = container(existing: {'C:/a'})
      ..listen(desktopTabsControllerProvider, (_, _) {});
    await ctl().restored.future;
    expect(locs(), const [FolderLocation('C:/a'), TrashLocation()]);
    expect(st().active, 1);
    // Back stacks aren't stored.
    expect(st().tabs.first.back, isEmpty);
  });

  test('bad JSON leaves one Home tab', () async {
    await settings.write(AppSettings.desktopTabs, '{nope');
    c.dispose();
    c = container()..listen(desktopTabsControllerProvider, (_, _) {});
    await ctl().restored.future;
    expect(locs(), [const HomeLocation()]);
  });
}
