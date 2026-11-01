import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/router.dart';
import 'package:kfm/app/theme/app_tokens.dart';
import 'package:kfm/features/connect/data/connect_providers.dart';
import 'package:kfm/features/connect/data/discovery.dart';
import 'package:kfm/features/connect/data/pairing_client.dart';
import 'package:kfm/features/connect/domain/pairing.dart';
import 'package:kfm/features/connect/domain/remote_connection_state.dart';
import 'package:kfm/features/connect/ui/connect_controller.dart';
import 'package:kfm/features/connect/ui/remote_connection_controller.dart';
import 'package:kfm/l10n/generated/app_localizations.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// "Connect to a device" (TASK-N2): scan the QR, or type the code of a
/// nearby / typed-address device, then wait for the other side to accept.
class ConnectScreen extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(connectControllerProvider);
    final controller = ref.read(connectControllerProvider.notifier);
    final spacing = context.tokens.spacing;
    final canGoBack = switch (state) {
      ConnectScanning() ||
      ConnectCameraDenied() ||
      ConnectPickDevice() ||
      ConnectEnterCode() => true,
      _ => false,
    };
    return PopScope(
      canPop: !canGoBack,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (state is ConnectEnterCode) {
          controller.typeCode();
        } else {
          controller.choose();
        }
      },
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.connectToDevice)),
        body: SafeArea(
          child: Padding(
            padding: EdgeInsetsDirectional.all(spacing * 2),
            child: switch (state) {
              ConnectChoose() => const _Choose(),
              ConnectScanning() => const _Scanner(),
              ConnectCameraDenied(:final permanently) => _CameraDenied(
                permanently: permanently,
              ),
              ConnectPickDevice() => const _PickDevice(),
              ConnectEnterCode() => _EnterCode(state: state),
              ConnectWorking(:final name) => _Progress(
                title: l10n.connectConnecting,
                name: name,
              ),
              ConnectWaiting(:final name, :final words) => _Progress(
                title: l10n.connectWaiting(name),
                name: name,
                words: words,
              ),
              ConnectConnected(:final peerName, :final roots) =>
                RefreshIndicator(
                  onRefresh: controller.refreshRoots,
                  child: _Message(
                    icon: Icons.check_circle_outline,
                    title: l10n.connectConnected(peerName),
                    body: roots.isEmpty
                        ? l10n.connectNoFoldersYet(peerName)
                        : l10n.connectFoldersShared(roots.length),
                    actions: [
                      OutlinedButton(
                        onPressed: () => unawaited(controller.disconnect()),
                        child: Text(l10n.connectDisconnect),
                      ),
                      if (ref.watch(remoteConnectionControllerProvider)
                          case RemoteConnected(:final peerFingerprint)
                          when roots.isNotEmpty)
                        FilledButton(
                          onPressed: () => unawaited(
                            context.push(
                              AppRoutes.connectBrowseFor(peerFingerprint),
                            ),
                          ),
                          child: Text(l10n.remoteBrowseAction(peerName)),
                        ),
                    ],
                  ),
                ),
              ConnectDisconnected(:final name, :final reason) => _Message(
                icon: Icons.link_off,
                title: switch (reason) {
                  DisconnectReason.remoteStopped =>
                    l10n.connectDisconnectedStopped(name),
                  DisconnectReason.networkLost =>
                    l10n.connectDisconnectedNetwork(name),
                  DisconnectReason.unauthorized ||
                  DisconnectReason.userClosed => l10n.connectDisconnected(name),
                },
                actions: [
                  FilledButton(
                    onPressed: controller.choose,
                    child: Text(l10n.connectBack),
                  ),
                ],
              ),
              ConnectFailed() => _Message(
                icon: Icons.error_outline,
                title: pairingFailureMessage(l10n, state.failure, state.name),
                actions: [
                  OutlinedButton(
                    onPressed: controller.choose,
                    child: Text(l10n.connectBack),
                  ),
                  FilledButton(
                    onPressed: controller.retry,
                    child: Text(l10n.connectTryAgain),
                  ),
                ],
              ),
            },
          ),
        ),
      ),
    );
  }
}

/// One message per [PairingFailure] (every N1 error code is covered).
String pairingFailureMessage(
  AppLocalizations l10n,
  PairingFailure failure,
  String? name,
) {
  final who = (name == null || name.trim().isEmpty)
      ? l10n.connectOtherDevice
      : name;
  return switch (failure) {
    PairingFailure.unreachable => l10n.connectErrorUnreachable,
    PairingFailure.wrongDevice => l10n.connectErrorWrongDevice(who),
    PairingFailure.wrongCode => l10n.connectErrorWrongCode(who),
    PairingFailure.secretUsed => l10n.connectErrorSecretUsed,
    PairingFailure.expired => l10n.connectErrorExpired,
    PairingFailure.tooManyAttempts => l10n.connectErrorTooMany,
    PairingFailure.busy => l10n.connectErrorBusy(who),
    PairingFailure.declined => l10n.connectErrorDeclined(who),
    PairingFailure.timedOut => l10n.connectErrorTimedOut(who),
    PairingFailure.cancelled => l10n.connectErrorCancelled,
    PairingFailure.unsupportedVersion => l10n.connectUpdateKfm,
    PairingFailure.pairingFailed => l10n.connectErrorFailed,
    PairingFailure.network => l10n.connectErrorNetwork(who),
    PairingFailure.badResponse => l10n.connectErrorBadResponse(who),
  };
}

class _Choose extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final spacing = context.tokens.spacing;
    final controller = ref.read(connectControllerProvider.notifier);
    final canScan = ref.watch(cameraAccessProvider).canScan;
    return ListView(
      children: [
        Text(l10n.connectChooseHint, style: theme.textTheme.bodyLarge),
        SizedBox(height: spacing * 3),
        if (canScan)
          Card(
            child: ListTile(
              key: const ValueKey('connect-scan'),
              leading: const Icon(Icons.qr_code_scanner),
              title: Text(l10n.connectScanQr),
              subtitle: Text(l10n.connectScanQrHint),
              onTap: () => controller.scan().ignore(),
            ),
          ),
        Card(
          child: ListTile(
            key: const ValueKey('connect-type'),
            leading: const Icon(Icons.keyboard_outlined),
            title: Text(l10n.connectTypeCode),
            subtitle: Text(l10n.connectTypeCodeHint),
            onTap: controller.typeCode,
          ),
        ),
      ],
    );
  }
}

/// Shows a scan result that didn't start pairing.
void _scanHint(BuildContext context, ScanOutcome outcome) {
  final l10n = context.l10n;
  final text = switch (outcome) {
    ScanOutcome.notKfm => l10n.connectNotKfmCode,
    ScanOutcome.unsupportedVersion => l10n.connectUpdateKfm,
    _ => null,
  };
  if (text == null) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));
}

class _Scanner extends ConsumerStatefulWidget {
  const new();

  @override
  ConsumerState<_Scanner> createState() => _ScannerState();
}

class _ScannerState extends ConsumerState<_Scanner> {
  // Camera only while this view is shown (bundled ML Kit model, offline).
  final MobileScannerController _camera = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  final TextEditingController _debugLink = TextEditingController();
  String? _lastRejected;

  @override
  void dispose() {
    _camera.dispose().ignore();
    _debugLink.dispose();
    super.dispose();
  }

  void _handle(String raw) {
    if (raw == _lastRejected) return;
    final outcome = ref.read(connectControllerProvider.notifier).onScanned(raw);
    if (outcome == ScanOutcome.notKfm ||
        outcome == ScanOutcome.unsupportedVersion) {
      _lastRejected = raw;
      _scanHint(context, outcome);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final spacing = context.tokens.spacing;
    final radius = context.tokens.radius;
    final controller = ref.read(connectControllerProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.connectScanQrHint, textAlign: TextAlign.center),
        SizedBox(height: spacing * 2),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: MobileScanner(
              controller: _camera,
              onDetect: (capture) {
                for (final b in capture.barcodes) {
                  final raw = b.rawValue;
                  if (raw != null) {
                    _handle(raw);
                    return;
                  }
                }
              },
              errorBuilder: (context, error) => Center(
                child: Padding(
                  padding: EdgeInsetsDirectional.all(spacing * 2),
                  child: Text(
                    l10n.connectCameraDenied,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
        ),
        if (kDebugMode) ...[
          SizedBox(height: spacing),
          // Debug only: emulators can't scan, so the link can be pasted.
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const ValueKey('connect-debug-link'),
                  controller: _debugLink,
                  decoration: InputDecoration(
                    labelText: l10n.connectDebugPasteLabel,
                  ),
                ),
              ),
              TextButton(
                key: const ValueKey('connect-debug-link-go'),
                onPressed: () {
                  _lastRejected = null;
                  _handle(_debugLink.text.trim());
                },
                child: Text(l10n.connectDebugPasteGo),
              ),
            ],
          ),
        ],
        SizedBox(height: spacing),
        TextButton.icon(
          onPressed: controller.typeCode,
          icon: const Icon(Icons.keyboard_outlined),
          label: Text(l10n.connectTypeCode),
        ),
      ],
    );
  }
}

class _CameraDenied extends ConsumerWidget {
  const new({required this.permanently});

  final bool permanently;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final controller = ref.read(connectControllerProvider.notifier);
    return _Message(
      icon: Icons.no_photography_outlined,
      title: l10n.connectCameraDenied,
      actions: [
        if (permanently)
          OutlinedButton(
            onPressed: () =>
                ref.read(cameraAccessProvider).openSettings().ignore(),
            child: Text(l10n.connectOpenSettings),
          )
        else
          OutlinedButton(
            onPressed: () => controller.scan().ignore(),
            child: Text(l10n.connectAllowCamera),
          ),
        FilledButton(
          key: const ValueKey('connect-denied-type'),
          onPressed: controller.typeCode,
          child: Text(l10n.connectTypeCode),
        ),
      ],
    );
  }
}

class _PickDevice extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final spacing = context.tokens.spacing;
    final controller = ref.read(connectControllerProvider.notifier);
    final nearby = ref.watch(nearbyDevicesProvider);
    final me = ref.watch(deviceIdentityProvider).value?.fingerprint;
    final devices = [
      for (final d in nearby.value ?? const <NearbyDevice>[])
        if (me == null || d.fingerprintHint != me) d,
    ];
    return ListView(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.connectNearbyTitle,
                style: theme.textTheme.titleMedium,
              ),
            ),
            TextButton.icon(
              key: const ValueKey('connect-enter-address'),
              onPressed: () => _askAddress(context, ref),
              icon: const Icon(Icons.edit_outlined),
              label: Text(l10n.connectEnterAddress),
            ),
          ],
        ),
        SizedBox(height: spacing),
        if (nearby.hasError)
          Text(l10n.connectNearbyFailed)
        else if (devices.isEmpty)
          Row(
            children: [
              const SizedBox.square(
                dimension: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: spacing * 2),
              Expanded(child: Text(l10n.connectNearbySearching)),
            ],
          ),
        for (final d in devices)
          Card(
            child: ListTile(
              leading: const Icon(Icons.devices_outlined),
              title: Text(d.name),
              subtitle: Text(
                l10n.connectHostPort(d.address.host, d.address.port),
              ),
              onTap: () => controller.pickDevice(d),
            ),
          ),
      ],
    );
  }

  Future<void> _askAddress(BuildContext context, WidgetRef ref) async {
    final address = await showDialog<ShareAddress>(
      context: context,
      builder: (_) => const _AddressDialog(),
    );
    if (address != null) {
      ref.read(connectControllerProvider.notifier).enterAddress(address);
    }
  }
}

class _AddressDialog extends StatefulWidget {
  const new();

  @override
  State<_AddressDialog> createState() => _AddressDialogState();
}

class _AddressDialogState extends State<_AddressDialog> {
  final TextEditingController _text = TextEditingController();
  bool _invalid = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _submit() {
    final a = parseManualAddress(_text.text);
    if (a == null) {
      setState(() => _invalid = true);
      return;
    }
    Navigator.of(context).pop(a);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.connectEnterAddress),
      content: TextField(
        key: const ValueKey('connect-address-field'),
        controller: _text,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[0-9.:]'))],
        decoration: InputDecoration(
          labelText: l10n.connectAddressLabel,
          errorText: _invalid ? l10n.connectAddressInvalid : null,
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.connectCancel),
        ),
        FilledButton(
          key: const ValueKey('connect-address-next'),
          onPressed: _submit,
          child: Text(l10n.connectNext),
        ),
      ],
    );
  }
}

/// Uppercases, maps O→0 / I,L→1, drops invalid characters and groups as
/// `XXXX-XXXX` while typing.
class ShortCodeInputFormatter extends TextInputFormatter {
  const new({this.length = kShortCodeLength});

  final int length;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final chars = StringBuffer();
    for (final ch in newValue.text.split('')) {
      final c = ShortCode.canonicalChars(ch);
      if (c != null) chars.write(c);
    }
    var v = chars.toString();
    if (v.length > length) v = v.substring(0, length);
    final text = v.length > 4 ? '${v.substring(0, 4)}-${v.substring(4)}' : v;
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class _EnterCode extends ConsumerStatefulWidget {
  const new({required this.state});

  final ConnectEnterCode state;

  @override
  ConsumerState<_EnterCode> createState() => _EnterCodeState();
}

class _EnterCodeState extends ConsumerState<_EnterCode> {
  final TextEditingController _text = TextEditingController();
  bool _badChar = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  ShortCode? get _code => ShortCode.normalize(_text.text);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final spacing = context.tokens.spacing;
    final s = widget.state;
    final name = s.name;
    final code = _code;
    return ListView(
      children: [
        Text(
          name == null ? l10n.connectCodeForAddress : l10n.connectCodeFor(name),
          style: theme.textTheme.titleMedium,
        ),
        SizedBox(height: spacing),
        Text(
          l10n.connectHostPort(s.target.host, s.target.port),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: spacing * 2),
        TextField(
          key: const ValueKey('connect-code-field'),
          controller: _text,
          autofocus: true,
          autocorrect: false,
          enableSuggestions: false,
          textCapitalization: TextCapitalization.characters,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontFamily: 'monospace',
            letterSpacing: 4,
          ),
          inputFormatters: [
            // Flags a rejected character before the formatter drops it.
            TextInputFormatter.withFunction((oldValue, newValue) {
              final bad =
                  ShortCode.canonicalChars(newValue.text) == null &&
                  newValue.text.length > oldValue.text.length;
              if (bad != _badChar) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) setState(() => _badChar = bad);
                });
              }
              return newValue;
            }),
            const ShortCodeInputFormatter(),
          ],
          decoration: InputDecoration(
            labelText: l10n.connectCodeLabel,
            hintText: 'XXXX-XXXX',
            errorText: _badChar ? l10n.connectCodeInvalidChar : null,
          ),
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) {
            final c = _code;
            if (c != null) {
              ref.read(connectControllerProvider.notifier).submitCode(c);
            }
          },
        ),
        SizedBox(height: spacing * 3),
        FilledButton(
          key: const ValueKey('connect-code-submit'),
          onPressed: code == null
              ? null
              : () => ref
                    .read(connectControllerProvider.notifier)
                    .submitCode(code),
          child: Text(l10n.connectConnect),
        ),
      ],
    );
  }
}

class _Progress extends ConsumerWidget {
  const new({required this.title, required this.name, this.words = const []});

  final String title;
  final String? name;

  /// The 4-word phrase while waiting (N3); empty before.
  final List<String> words;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return _Message(
      icon: null,
      title: title,
      body: words.isEmpty ? null : l10n.pairCompareWords,
      words: words,
      actions: [
        OutlinedButton(
          key: const ValueKey('connect-cancel'),
          onPressed: ref.read(connectControllerProvider.notifier).cancel,
          child: Text(l10n.connectCancel),
        ),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  const new({
    required this.icon,
    required this.title,
    required this.actions,
    this.body,
    this.words = const [],
  });

  /// Null shows a progress indicator.
  final IconData? icon;
  final String title;
  final String? body;

  /// Fixed English words (ARB-exempt, `fingerprint_words.dart`).
  final List<String> words;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = context.tokens.spacing;
    // Full height, so pull-to-refresh works anywhere on the screen.
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon case final i?)
                Icon(i, size: 48, color: theme.colorScheme.onSurfaceVariant)
              else
                const CircularProgressIndicator(),
              SizedBox(height: spacing * 2),
              Text(
                title,
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              if (words.isNotEmpty) ...[
                SizedBox(height: spacing * 2),
                Text(
                  words.join(' '),
                  key: const ValueKey('connect-words'),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              if (body case final b?) ...[
                SizedBox(height: spacing),
                Text(b, textAlign: TextAlign.center),
              ],
              SizedBox(height: spacing * 3),
              Wrap(
                spacing: spacing * 2,
                runSpacing: spacing,
                alignment: WrapAlignment.center,
                children: actions,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
