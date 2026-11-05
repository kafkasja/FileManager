import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/core/db/settings/settings_repository.dart';
import 'package:kfm/core/platform/windows/index_roots.dart';
import 'package:kfm/core/platform/windows/windows_channel.dart';

import 'fake_windows_channel.dart';

void main() {
  group('known folders', () {
    test('fall back to the profile folders', () {
      expect(fallbackKnownFolders({'USERPROFILE': r'C:\Users\me'}), {
        KnownFolder.pictures: 'C:/Users/me/Pictures',
        KnownFolder.videos: 'C:/Users/me/Videos',
        KnownFolder.downloads: 'C:/Users/me/Downloads',
        KnownFolder.documents: 'C:/Users/me/Documents',
      });
      expect(fallbackKnownFolders(const {}), isEmpty);
    });
  });

  group('WindowsIndexRoots', () {
    late AppDatabase db;
    late DbWriteQueue queue;
    late SettingsRepository settings;
    late FakeWindowsChannel channel;
    late WindowsIndexRoots roots;

    setUp(() {
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      db = AppDatabase(NativeDatabase.memory());
      queue = DbWriteQueue();
      settings = SettingsRepository(db, queue);
      channel = FakeWindowsChannel(
        known: {
          KnownFolder.pictures: 'D:/Pics',
          KnownFolder.documents: 'C:/Users/me/Documents',
        },
      );
      roots = WindowsIndexRoots(
        settings: settings,
        channel: channel,
        environment: const {'USERPROFILE': r'C:\Users\me'},
      );
    });
    tearDown(() async {
      await queue.close();
      await db.close();
    });

    test('empty setting = the known folders from the channel', () async {
      expect(await roots.chosen(), ['D:/Pics', 'C:/Users/me/Documents']);
    });

    test('no native side: the profile folders', () async {
      final fallback = WindowsIndexRoots(
        settings: settings,
        channel: FakeWindowsChannel(missing: true),
        environment: const {'USERPROFILE': r'C:\Users\me'},
      );
      expect(await fallback.chosen(), hasLength(4));
    });

    test('add turns the defaults into a list; nested adds are no-ops; '
        'remove keeps the last; reset', () async {
      await roots.add(r'E:\Photos\');
      expect(await settings.read(AppSettings.windowsIndexRoots), [
        'D:/Pics',
        'C:/Users/me/Documents',
        'E:/Photos',
      ]);
      await roots.add('d:/pics/2024');
      expect(await roots.chosen(), hasLength(3));

      await roots.remove('d:/PICS');
      await roots.remove('C:/Users/me/Documents');
      expect(await roots.chosen(), ['E:/Photos']);
      await roots.remove('E:/Photos'); // the last one stays
      expect(await roots.chosen(), ['E:/Photos']);

      await roots.resetToDefaults();
      expect(await roots.chosen(), ['D:/Pics', 'C:/Users/me/Documents']);
    });
  });

  group('windowsDirectoryChanges', () {
    late Directory dir;

    setUp(() => dir = Directory.systemTemp.createTempSync('kfm_watch'));
    tearDown(() => dir.deleteSync(recursive: true));

    test('debounces events per kind and follows the roots', () {
      fakeAsync((async) {
        final a = '${dir.path}/a'.replaceAll(r'\', '/');
        final b = '${dir.path}/b'.replaceAll(r'\', '/');
        Directory(a).createSync();
        Directory(b).createSync();
        final watched = <String, StreamController<FileSystemEvent>>{};
        final roots = StreamController<List<String>>();
        final out = <String>[];
        final sub = windowsDirectoryChanges(
          roots.stream,
          watch: (root) =>
              (watched[root] = StreamController<FileSystemEvent>()).stream,
        ).listen((c) => out.add(c.type));

        roots.add([a, '${dir.path}/missing']);
        async.flushMicrotasks();
        expect(watched.keys, [a]); // a missing root isn't watched

        watched[a]!
          ..add(FileSystemCreateEvent('$a/1.jpg', false))
          ..add(FileSystemModifyEvent('$a/1.jpg', false, true));
        async.elapse(const Duration(seconds: 1));
        watched[a]!.add(FileSystemCreateEvent('$a/2.jpg', false));
        async.elapse(const Duration(seconds: 1));
        expect(out, isEmpty); // still settling
        async.elapse(const Duration(seconds: 2));
        expect(out, ['insert']);

        watched[a]!.add(FileSystemDeleteEvent('$a/1.jpg', false));
        async.elapse(windowsChangeDebounce);
        expect(out, ['insert', 'delete']);

        roots.add([b]);
        async.flushMicrotasks();
        expect(watched[a]!.hasListener, isFalse);
        expect(watched[b]!.hasListener, isTrue);

        unawaited(sub.cancel());
        async.flushMicrotasks();
        expect(watched[b]!.hasListener, isFalse);
      });
    });

    test('a paused drive stops its watchers until resumed (eject)', () {
      fakeAsync((async) {
        final a = '${dir.path}/a'.replaceAll(r'\', '/');
        final b = '${dir.path}/b'.replaceAll(r'\', '/');
        Directory(a).createSync();
        Directory(b).createSync();
        final watched = <String, StreamController<FileSystemEvent>>{};
        final pauses = WatchPauses();
        final sub = windowsDirectoryChanges(
          Stream.value([a, b]),
          pauses: pauses,
          // An onCancel future: a bare controller's cancel completes in the
          // root zone, outside fakeAsync.
          watch: (root) => (watched[root] = StreamController<FileSystemEvent>(
            onCancel: () async {},
          )).stream,
        ).listen((_) {});
        async.flushMicrotasks();
        expect(watched[a]!.hasListener, isTrue);

        var paused = false;
        unawaited(pauses.pause(a).then((_) => paused = true));
        async.flushMicrotasks();
        expect(paused, isTrue);
        expect(watched[a]!.hasListener, isFalse); // handle closed
        expect(watched[b]!.hasListener, isTrue); // other drive untouched
        expect(pauses.isPaused('$a/DCIM'), isTrue);

        // Roots changing while paused don't restart it.
        final oldB = watched[b];
        unawaited(pauses.pause('${dir.path}/none'));
        async.flushMicrotasks();
        expect(watched[a]!.hasListener, isFalse);
        expect(watched[b], same(oldB));

        // Eject refused / cancelled: watching again.
        unawaited(pauses.resume(a));
        async.flushMicrotasks();
        expect(watched[a]!.hasListener, isTrue);

        unawaited(sub.cancel());
        async.flushMicrotasks();
      });
    });

    test('a real file dropped into a root is reported', () async {
      final root = dir.path.replaceAll(r'\', '/');
      final changes = windowsDirectoryChanges(
        Stream.value([root]),
        debounce: const Duration(milliseconds: 200),
      );
      final first = changes.first.timeout(const Duration(seconds: 5));
      // Let the watcher start before the file appears.
      await Future<void>.delayed(const Duration(milliseconds: 200));
      File('$root/new.jpg').writeAsBytesSync([1, 2, 3]);
      expect((await first).type, 'insert');
    }, testOn: 'windows');
  });
}
