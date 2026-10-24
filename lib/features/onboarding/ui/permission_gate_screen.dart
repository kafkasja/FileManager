import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/theme/app_tokens.dart';
import 'package:kfm/core/platform/permissions/storage_access.dart';
import 'package:kfm/core/platform/permissions/storage_access_provider.dart';

/// Shown by the router while photos & videos access is missing (F4).
class PermissionGateScreen extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final access = ref.watch(storageAccessControllerProvider);
    final controller = ref.read(storageAccessControllerProvider.notifier);
    final text = Theme.of(context).textTheme;
    final gap = SizedBox(height: context.tokens.spacing * 2);

    final List<Widget> content;
    if (access.hasError && !access.isLoading) {
      content = [
        Text(l10n.permCheckFailed, textAlign: TextAlign.center),
        gap,
        FilledButton(onPressed: controller.recheck, child: Text(l10n.retry)),
      ];
    } else if (access.isLoading && !access.hasValue) {
      content = [const CircularProgressIndicator()];
    } else {
      final permanentlyDenied =
          access.value?.media == MediaAccess.permanentlyDenied;
      content = [
        Icon(
          Icons.photo_library_outlined,
          size: 64,
          color: Theme.of(context).colorScheme.primary,
        ),
        gap,
        Text(
          l10n.permGateTitle,
          style: text.headlineSmall,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: context.tokens.spacing),
        Text(
          permanentlyDenied ? l10n.permPermanentlyDeniedHelp : l10n.permGateWhy,
          style: text.bodyLarge,
          textAlign: TextAlign.center,
        ),
        gap,
        if (permanentlyDenied)
          FilledButton(
            onPressed: controller.openAppSettings,
            child: Text(l10n.permOpenSettings),
          )
        else
          FilledButton(
            onPressed: access.isLoading ? null : controller.requestMedia,
            child: Text(l10n.permAllow),
          ),
      ];
    }

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsetsDirectional.all(context.tokens.spacing * 3),
            child: Column(mainAxisSize: MainAxisSize.min, children: content),
          ),
        ),
      ),
    );
  }
}
