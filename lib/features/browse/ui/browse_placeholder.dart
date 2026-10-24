import 'package:flutter/material.dart';
import 'package:kfm/app/l10n_ext.dart';

/// Replaced by the browse screen in B1.
class BrowsePlaceholder extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.l10n.tabBrowse)),
    body: Center(child: Text(context.l10n.browsePlaceholder)),
  );
}
