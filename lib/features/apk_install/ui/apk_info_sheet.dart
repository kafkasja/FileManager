import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/theme/app_tokens.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/utils/format.dart';
import 'package:kfm/features/apk_install/data/apk_platform.dart';
import 'package:kfm/features/apk_install/domain/apk_info.dart';
import 'package:kfm/features/apk_install/ui/apk_install_controller.dart';
import 'package:kfm/l10n/generated/app_localizations.dart';

/// TASK-X5: what an `.apk` is, then Install (Android's own installer).
Future<void> showApkInfoSheet(BuildContext context, FileRef file) =>
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => ApkInfoSheet(file: file),
    );

class ApkInfoSheet extends ConsumerStatefulWidget {
  const new({required this.file, super.key});

  final FileRef file;

  @override
  ConsumerState<ApkInfoSheet> createState() => _ApkInfoSheetState();
}

class _ApkInfoSheetState extends ConsumerState<ApkInfoSheet> {
  /// Only while waiting for the user in "Install unknown apps".
  AppLifecycleListener? _resume;
  ApkInstallOutcome? _outcome;
  bool _busy = false;

  ApkInstallControllerProvider get _provider =>
      apkInstallControllerProvider(widget.file);

  @override
  void dispose() {
    _resume?.dispose();
    super.dispose();
  }

  Future<void> _run(Future<ApkInstallOutcome> Function() step) async {
    setState(() => _busy = true);
    ApkInstallOutcome outcome;
    try {
      outcome = await step();
    } on Object catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text(context.l10n.apkInstallFailed('$e'))),
      );
      return;
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _outcome = outcome;
    });
  }

  Future<void> _install() => _run(() => ref.read(_provider.notifier).install());

  Future<void> _openSettings() async {
    final notifier = ref.read(_provider.notifier);
    _resume?.dispose();
    _resume = AppLifecycleListener(
      onResume: () {
        _resume?.dispose();
        _resume = null;
        unawaited(_run(notifier.resumeAfterSettings));
      },
    );
    if (!await notifier.openPermissionSettings()) {
      _resume?.dispose();
      _resume = null;
      if (mounted) {
        setState(() => _outcome = ApkInstallOutcome.permissionDenied);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final spacing = context.tokens.spacing;
    final async = ref.watch(_provider);
    return SafeArea(
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(
          spacing * 2,
          0,
          spacing * 2,
          spacing * 2,
        ),
        child: switch (async) {
          AsyncData(:final value) => _info(context, l10n, value),
          AsyncError(:final error) => _error(context, l10n, error),
          _ => const Padding(
            padding: EdgeInsetsDirectional.all(24),
            child: Center(child: CircularProgressIndicator()),
          ),
        },
      ),
    );
  }

  Widget _error(BuildContext context, AppLocalizations l10n, Object error) {
    final text = switch (error) {
      ApkException(failure: ApkFailure.invalid) => l10n.apkInvalid,
      ApkException(failure: ApkFailure.noSpace) => l10n.apkNoSpace,
      _ => l10n.apkReadFailed('$error'),
    };
    return ListTile(
      key: const ValueKey('apk-error'),
      leading: Icon(
        Icons.error_outline,
        color: Theme.of(context).colorScheme.error,
      ),
      title: Text(text),
    );
  }

  Widget _info(BuildContext context, AppLocalizations l10n, ApkInfo info) {
    final scheme = Theme.of(context).colorScheme;
    final spacing = context.tokens.spacing;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final version = info.versionName.isEmpty
        ? '${info.versionCode}'
        : info.versionName;
    final installed = info.installedVersionName?.isNotEmpty ?? false
        ? info.installedVersionName!
        : '${info.installedVersionCode ?? ''}';
    final status = switch (info) {
      ApkInfo(isUpdate: true) => l10n.apkUpdateFromTo(installed, version),
      ApkInfo(isSameVersion: true) => l10n.apkSameVersion,
      ApkInfo(isDowngrade: true) => l10n.apkDowngrade(installed),
      ApkInfo(isNewApp: true) => l10n.apkNewApp,
      _ => l10n.apkUnknownInstalled,
    };
    final icon = info.iconPng;
    final warn = TextStyle(color: scheme.error);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          contentPadding: EdgeInsetsDirectional.zero,
          leading: icon == null
              ? const Icon(Icons.android, size: 48)
              : Image.memory(icon, width: 48, height: 48),
          title: Text(info.label, key: const ValueKey('apk-label')),
          subtitle: Text(
            l10n.apkPackageLine(info.packageName, version),
            key: const ValueKey('apk-package'),
          ),
        ),
        Text(formatBytes(widget.file.sizeBytes, locale: locale)),
        SizedBox(height: spacing),
        Text(
          status,
          key: const ValueKey('apk-status'),
          style: info.isDowngrade ? warn : null,
        ),
        if (info.signerMismatch) ...[
          SizedBox(height: spacing),
          Text(
            l10n.apkSignerMismatch,
            key: const ValueKey('apk-signer-mismatch'),
            style: warn,
          ),
        ] else if (!info.installedVisible) ...[
          SizedBox(height: spacing),
          Text(l10n.apkSignerUnknown),
        ],
        SizedBox(height: spacing),
        Text(l10n.apkTrustNote, style: Theme.of(context).textTheme.bodySmall),
        SizedBox(height: spacing * 2),
        ..._actions(l10n, warn),
      ],
    );
  }

  List<Widget> _actions(AppLocalizations l10n, TextStyle warn) {
    final busy = _busy;
    return switch (_outcome) {
      ApkInstallOutcome.needsPermission => [
        Text(l10n.apkPermissionWhy, key: const ValueKey('apk-permission-why')),
        SizedBox(height: context.tokens.spacing),
        FilledButton(
          key: const ValueKey('apk-open-settings'),
          onPressed: busy ? null : () => unawaited(_openSettings()),
          child: Text(l10n.apkOpenSettings),
        ),
      ],
      ApkInstallOutcome.permissionDenied => [
        Text(
          l10n.apkPermissionDenied,
          key: const ValueKey('apk-permission-denied'),
          style: warn,
        ),
        SizedBox(height: context.tokens.spacing),
        OutlinedButton(
          onPressed: busy ? null : () => unawaited(_openSettings()),
          child: Text(l10n.apkOpenSettings),
        ),
      ],
      ApkInstallOutcome.noInstaller => [Text(l10n.apkNoInstaller, style: warn)],
      ApkInstallOutcome.handedOff || null => [
        FilledButton.icon(
          key: const ValueKey('apk-install'),
          onPressed: busy ? null : () => unawaited(_install()),
          icon: const Icon(Icons.install_mobile),
          label: Text(l10n.apkInstall),
        ),
      ],
    };
  }
}
