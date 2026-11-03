import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kfm/app/router.dart';
import 'package:kfm/desktop/browse/desktop_browse_controller.dart';

/// Opens [folder] in desktop Browse (sidebar Places, breadcrumbs).
void openDesktopFolder(BuildContext context, WidgetRef ref, String folder) {
  ref.read(desktopBrowseControllerProvider.notifier).open(folder);
  GoRouter.of(context).go(AppRoutes.browse);
}
