import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/features/connect/ui/connect_controller.dart';
import 'package:kfm/features/connect/ui/connect_screen.dart';
import 'package:kfm/features/connect/ui/remembered_devices_screen.dart';
import 'package:kfm/features/connect/ui/share_screen.dart';
import 'package:kfm/features/transfers/ui/transfers_screen.dart';

/// What the left pane of Devices shows.
enum DevicesPane { start, share, receive, connect }

/// Desktop Devices (TASK-PL3 step 5): on the left this PC's QR and typed
/// code (Share / Receive: the phone's Share screen, which runs the server
/// while it is shown) or "Type a code" to connect to another device; on
/// the right the remembered and connected devices; transfers below. Nothing
/// is shared until the user picks Share or Receive (rule 7).
class DesktopDevicesScreen extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<DesktopDevicesScreen> createState() =>
      _DesktopDevicesScreenState();
}

class _DesktopDevicesScreenState extends ConsumerState<DesktopDevicesScreen> {
  DevicesPane _pane = DevicesPane.start;

  void _show(DevicesPane pane) {
    final connect = ref.read(connectControllerProvider.notifier);
    // A PC has no camera: "Type a code" goes straight to the code field.
    if (pane == DevicesPane.connect) connect.typeCode();
    if (_pane == DevicesPane.connect && pane == DevicesPane.start) {
      connect.choose();
    }
    setState(() => _pane = pane);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final left = switch (_pane) {
      DevicesPane.start => _Start(onPick: _show),
      DevicesPane.share => const ShareScreen(),
      DevicesPane.receive => const ShareScreen(receive: true),
      DevicesPane.connect => const ConnectScreen(),
    };
    return Column(
      children: [
        Expanded(
          flex: 3,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Column(
                  children: [
                    if (_pane != DevicesPane.start)
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(
                            8,
                            8,
                            8,
                            0,
                          ),
                          child: TextButton.icon(
                            key: const ValueKey('devices-back'),
                            onPressed: () => _show(DevicesPane.start),
                            icon: const Icon(Icons.arrow_back, size: 18),
                            label: Text(
                              _pane == DevicesPane.connect
                                  ? l10n.desktopBrowseBack
                                  : l10n.shareStop,
                            ),
                          ),
                        ),
                      ),
                    Expanded(child: left),
                  ],
                ),
              ),
              const VerticalDivider(width: 1),
              const Expanded(child: RememberedDevicesScreen()),
            ],
          ),
        ),
        const Divider(height: 1),
        const Expanded(flex: 2, child: TransfersScreen()),
      ],
    );
  }
}

class _Start extends StatelessWidget {
  const new({required this.onPick});

  final ValueChanged<DevicesPane> onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    Widget card(
      Key key,
      IconData icon,
      String title,
      String subtitle,
      DevicesPane pane,
    ) => Card(
      child: ListTile(
        key: key,
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        onTap: () => onPick(pane),
      ),
    );
    return ListView(
      padding: const EdgeInsetsDirectional.all(16),
      children: [
        Text(l10n.desktopDevicesTitle, style: theme.textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(
          l10n.desktopDevicesHint,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        card(
          const ValueKey('devices-share'),
          Icons.qr_code_2,
          l10n.shareTitle,
          l10n.desktopDevicesShareHint,
          DevicesPane.share,
        ),
        card(
          const ValueKey('devices-receive'),
          Icons.move_to_inbox_outlined,
          l10n.receiveFiles,
          l10n.receiveFilesHint,
          DevicesPane.receive,
        ),
        card(
          const ValueKey('devices-connect'),
          Icons.keyboard_outlined,
          l10n.connectTypeCode,
          l10n.desktopDevicesConnectHint,
          DevicesPane.connect,
        ),
      ],
    );
  }
}
