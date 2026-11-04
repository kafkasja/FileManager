import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/features/background_jobs/data/background_jobs_providers.dart';
import 'package:kfm/features/background_jobs/domain/job_progress.dart';
import 'package:kfm/features/transfers/ui/transfers_screen.dart';

import '../../helpers/pump_app.dart';

JobProgress _job(String key, {JobPhase phase = JobPhase.running}) =>
    JobProgress(
      key: key,
      kind: JobKind.send,
      target: const DeviceTarget('PC'),
      phase: phase,
      files: 3,
      bytesDone: 25,
      bytesTotal: 100,
    );

void main() {
  testWidgets('no jobs: no indicator', (tester) async {
    await pumpApp(tester);
    expect(find.byKey(const ValueKey('jobs-indicator')), findsNothing);
  });

  testWidgets('shows on every tab while a job runs; a tap opens Transfers', (
    tester,
  ) async {
    await pumpApp(
      tester,
      overrides: [
        jobsSnapshotProvider.overrideWith(
          (ref) => Stream.value(JobsSnapshot(jobs: [_job('t:1')])),
        ),
      ],
    );
    final indicator = find.byKey(const ValueKey('jobs-indicator'));
    expect(indicator, findsOneWidget);
    expect(find.text('Sending 3 files to PC'), findsOneWidget);
    expect(find.text('25%'), findsOneWidget);

    for (final tab in ['Browse', 'Trash', 'Settings']) {
      await tester.tap(find.text(tab).last);
      await tester.pumpAndSettle();
      expect(indicator, findsOneWidget, reason: tab);
    }

    await tester.tap(indicator);
    await tester.pumpAndSettle();
    expect(find.byType(TransfersScreen), findsOneWidget);
  });

  testWidgets('paused only: says so', (tester) async {
    await pumpApp(
      tester,
      overrides: [
        jobsSnapshotProvider.overrideWith(
          (ref) => Stream.value(
            JobsSnapshot(jobs: [_job('t:1', phase: JobPhase.paused)]),
          ),
        ),
      ],
    );
    expect(find.text('Paused · Sending 3 files to PC'), findsOneWidget);
  });
}
