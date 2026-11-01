import 'package:flutter/material.dart';
import 'package:kfm/app/l10n_ext.dart';

/// `/connect` placeholder until N2 builds the Connect screen (QR scan,
/// typed code, nearby devices).
class ConnectScreen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.connectToDevice)),
      body: Center(child: Text(l10n.connectComingSoon)),
    );
  }
}
