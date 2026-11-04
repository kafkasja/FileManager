import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/features/background_jobs/domain/job_notice.dart';
import 'package:kfm/features/background_jobs/domain/job_progress.dart';
import 'package:kfm/l10n/generated/app_localizations.dart';

const int _gb = 1024 * 1024 * 1024;
const int _mb = 1024 * 1024;

NoticeFormat _format(String lang) => NoticeFormat(
  l10n: lookupAppLocalizations(Locale(lang)),
  locale: lang,
  placeName: (t) => t.placeId == 'sd' ? 'SD card' : t.folder,
);

JobProgress _job(
  String key, {
  JobKind kind = JobKind.send,
  JobPhase phase = JobPhase.running,
  int files = 3,
  int done = 0,
  int failed = 0,
  int bytesDone = 0,
  int bytesTotal = 0,
  JobTarget target = const DeviceTarget('PC'),
  bool controllable = true,
}) => JobProgress(
  key: key,
  kind: kind,
  target: target,
  phase: phase,
  files: files,
  filesDone: done,
  filesFailed: failed,
  bytesDone: bytesDone,
  bytesTotal: bytesTotal,
  controllable: controllable,
);

void main() {
  final big = _job(
    't:1',
    bytesDone: (1.2 * _gb).round(),
    bytesTotal: (4.5 * _gb).round(),
  );
  final snapshot = JobsSnapshot(jobs: [big], bytesPerSecond: 12.0 * _mb);

  test('one running job: title, bytes, speed, time left, actions', () {
    final n = ongoingNotice(snapshot, _format('en'))!;
    expect(n.title, 'Sending 3 files to PC');
    expect(n.text, '1.2 GB of 4.5 GB · 12 MB/s · 5 min left');
    expect(n.percent, 26);
    expect(n.actions, [NoticeAction.pause, NoticeAction.cancel]);
  });

  test('several jobs: combined title with the percentage', () {
    final s = JobsSnapshot(
      jobs: [
        _job('t:1', bytesDone: 30, bytesTotal: 100),
        _job(
          'l:2',
          kind: JobKind.localCopy,
          target: const PlaceTarget('sd', '/x'),
          bytesDone: 46,
          bytesTotal: 100,
        ),
      ],
    );
    final n = ongoingNotice(s, _format('en'))!;
    expect(n.title, '2 transfers · 38%');
    expect(n.text, '76 B of 200 B');
  });

  test('every text is rendered in nl and tr (no English fallback)', () {
    final en = ongoingNotice(snapshot, _format('en'))!;
    final nl = ongoingNotice(snapshot, _format('nl'))!;
    final tr = ongoingNotice(snapshot, _format('tr'))!;
    expect(nl.title, isNot(en.title));
    expect(tr.title, isNot(en.title));
    // Locale number formatting: decimal comma.
    expect(nl.text, contains('1,2 GB'));
    expect(nl.text, contains('4,5 GB'));
    expect(tr.text, contains('1,2 GB'));
    expect(nl.text, isNot(contains('left')));
    expect(tr.text, isNot(contains('left')));

    for (final lang in ['en', 'nl', 'tr']) {
      final f = _format(lang);
      final paused = pausedNotice(
        JobsSnapshot(jobs: [_job('t:1', phase: JobPhase.paused)]),
        f,
        timeout: true,
      )!;
      final ended = endNotice([
        JobEnd(_job('t:1', phase: JobPhase.done, done: 2, failed: 1)),
      ], f)!;
      final local = endNotice([
        JobEnd(
          _job(
            'l:1',
            kind: JobKind.localCopy,
            phase: JobPhase.done,
            done: 120,
            files: 120,
            target: const PlaceTarget('sd', '/x'),
          ),
        ),
      ], f)!;
      final many = ongoingNotice(
        JobsSnapshot(
          jobs: [
            _job('t:1', bytesDone: 1, bytesTotal: 2),
            _job('i:2', kind: JobKind.incoming, bytesTotal: 2),
          ],
        ),
        f,
      )!;
      for (final s in [
        paused.title,
        paused.text,
        ended.title,
        ended.text,
        local.title,
        many.title,
        f.l10n.jobsChannelProgress,
        f.l10n.jobsChannelResults,
        f.timeLeft(const Duration(minutes: 75)),
      ]) {
        expect(s, isNotEmpty, reason: lang);
        expect(s, isNot(contains('{')), reason: '$lang: $s');
      }
      if (lang != 'en') {
        final e = _format('en');
        expect(paused.text, isNot(e.l10n.jobsPausedOpenKfm));
        expect(ended.text, isNot(e.l10n.jobsEndFailed(1)));
        expect(local.title, isNot(e.l10n.jobsEndCopied(120, 'SD card')));
        expect(f.l10n.jobsChannelProgress, isNot(e.l10n.jobsChannelProgress));
      }
    }
    // Turkish percent sign goes first.
    expect(
      ongoingNotice(
        JobsSnapshot(
          jobs: [_job('t:1', bytesDone: 38, bytesTotal: 100), _job('t:2')],
        ),
        _format('tr'),
      )!.title,
      contains('%38'),
    );
  });

  test('paused only: dismissible notice with Resume and Cancel', () {
    final s = JobsSnapshot(
      jobs: [
        _job('t:1', phase: JobPhase.paused, bytesDone: 50, bytesTotal: 100),
      ],
    );
    expect(ongoingNotice(s, _format('en')), isNull);
    final n = pausedNotice(s, _format('en'))!;
    expect(n.title, 'Paused · Sending 3 files to PC');
    expect(n.text, '50 B of 100 B');
    expect(n.actions, [NoticeAction.resume, NoticeAction.cancel]);
    final t = pausedNotice(s, _format('en'), timeout: true)!;
    expect(t.text, 'Paused, open KFM to continue');
    expect(t.actions, isEmpty);
  });

  test('end notices: sent, failed, local, several, cancelled', () {
    final f = _format('en');
    expect(
      endNotice([
        JobEnd(_job('t:1', phase: JobPhase.done, done: 3, bytesTotal: 1024)),
      ], f),
      const JobNotice(title: 'Sent 3 files to PC', text: '1 KB'),
    );
    final failed = endNotice([
      JobEnd(_job('t:1', phase: JobPhase.failed, done: 2, failed: 1)),
    ], f)!;
    expect(failed.title, 'Sent 2 files to PC');
    expect(failed.text, '1 file failed · Tap to see');
    expect(failed.failed, isTrue);
    expect(
      endNotice([
        JobEnd(_job('t:1', phase: JobPhase.failed, failed: 3)),
      ], f)!.title,
      'Transfer failed',
    );
    expect(
      endNotice([
        JobEnd(
          _job(
            'l:1',
            kind: JobKind.localCopy,
            phase: JobPhase.done,
            done: 120,
            files: 120,
            target: const PlaceTarget('sd', '/x'),
          ),
        ),
      ], f)!.title,
      'Copied 120 files to SD card',
    );
    expect(
      endNotice([
        JobEnd(
          _job('i:1', kind: JobKind.incoming, phase: JobPhase.done, done: 1),
        ),
        JobEnd(_job('t:2', phase: JobPhase.done, done: 1)),
      ], f)!.title,
      '2 transfers finished',
    );
    expect(
      endNotice([JobEnd(_job('t:1', phase: JobPhase.cancelled))], f),
      isNull,
    );
  });

  test('incoming uploads have no Pause / Cancel', () {
    final n = ongoingNotice(
      JobsSnapshot(
        jobs: [
          _job(
            'i:x',
            kind: JobKind.incoming,
            files: 1,
            controllable: false,
            bytesTotal: 10,
          ),
        ],
      ),
      _format('en'),
    )!;
    expect(n.title, 'Receiving 1 file from PC');
    expect(n.actions, isEmpty);
    expect(n.text, '0 B of 10 B');
  });

  test('time left formatting', () {
    final f = _format('en');
    expect(f.timeLeft(const Duration(seconds: 40)), '40 s');
    expect(f.timeLeft(const Duration(seconds: 61)), '2 min');
    expect(f.timeLeft(const Duration(minutes: 75)), '1 h 15 min');
  });
}
