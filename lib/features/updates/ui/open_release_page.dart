import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/core/files/android/files_channel.dart';
import 'package:kfm/features/updates/domain/release_info.dart';

/// Opens an https page in the browser; false when no app can (X7).
typedef UrlOpener = Future<bool> Function(Uri url);

final urlOpenerProvider = Provider<UrlOpener>(
  (ref) => Platform.isAndroid
      ? FilesChannel().openUrl
      : (_) async => throw UnsupportedError('no browser hand-off yet'),
);

/// "Download": the release page in the browser. KFM never downloads or
/// installs the update itself. Only KFM's own release pages are opened.
Future<void> openReleasePage(
  BuildContext context,
  WidgetRef ref,
  ReleaseInfo release,
) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final l10n = context.l10n;
  var opened = false;
  Object? error;
  if (isReleasePage(release.pageUrl)) {
    try {
      opened = await ref.read(urlOpenerProvider)(release.pageUrl);
    } on Object catch (e) {
      error = e;
    }
  }
  if (!opened) {
    messenger?.showSnackBar(
      SnackBar(
        content: Text(
          error == null
              ? l10n.updatesNoBrowser
              : l10n.updatesOpenFailed('$error'),
        ),
      ),
    );
  }
}
