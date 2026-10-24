import 'package:flutter/material.dart';
import 'package:kfm/app/app_info.dart';
import 'package:kfm/app/l10n_ext.dart';

/// Version + the app's promises (F6).
class AboutSection extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: Text(l10n.appTitle),
          subtitle: Text(l10n.aboutVersion(appVersion)),
        ),
        ListTile(
          leading: const Icon(Icons.verified_user_outlined),
          title: Text(l10n.aboutPromise),
        ),
      ],
    );
  }
}
