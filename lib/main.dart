import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/app.dart';
import 'package:kfm/core/background/background_scheduler.dart';
import 'package:kfm/features/trash/data/pending_purge_worker.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ProviderScope(
      overrides: [
        if (Platform.isAndroid)
          backgroundSchedulerProvider.overrideWithValue(
            WorkmanagerScheduler(pendingPurgeDispatcher),
          ),
      ],
      child: const App(),
    ),
  );
}
