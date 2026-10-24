import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/core/platform/permissions/storage_access.dart';
import 'package:kfm/core/platform/permissions/storage_access_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'limited_access_banner.g.dart';

/// Dismissed for the rest of this app run.
@Riverpod(keepAlive: true)
class LimitedBannerDismissed extends _$LimitedBannerDismissed {
  @override
  bool build() => false;

  void dismiss() => state = true;
}

/// "KFM can only see some photos. Allow all" (API 34+ partial access).
class LimitedAccessBanner extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final limited =
        ref.watch(storageAccessControllerProvider).value?.media ==
        MediaAccess.limited;
    if (!limited || ref.watch(limitedBannerDismissedProvider)) {
      return const SizedBox.shrink();
    }
    final l10n = context.l10n;
    return MaterialBanner(
      content: Text(l10n.limitedBanner),
      leading: const Icon(Icons.photo_library_outlined),
      actions: [
        TextButton(
          onPressed: ref.read(limitedBannerDismissedProvider.notifier).dismiss,
          child: Text(l10n.dismiss),
        ),
        TextButton(
          onPressed: ref
              .read(storageAccessControllerProvider.notifier)
              .requestMedia,
          child: Text(l10n.limitedAllowAll),
        ),
      ],
    );
  }
}
