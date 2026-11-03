import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kfm/app/router.dart';
import 'package:kfm/features/browse/domain/browse_source_chip.dart';
import 'package:kfm/features/browse/ui/browse_controller.dart';

/// Opens [folder] in Browse (sidebar Places, breadcrumbs).
void openDesktopFolder(BuildContext context, WidgetRef ref, String folder) {
  final container = ProviderScope.containerOf(context, listen: false);
  GoRouter.of(context).go(AppRoutes.browse);
  WidgetsBinding.instance.addPostFrameCallback((_) {
    container.read(browseViewControllerProvider.notifier)
      ..setLayout(BrowseLayout.folders)
      ..openFolder(folder);
  });
}
