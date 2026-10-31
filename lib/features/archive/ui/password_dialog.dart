import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/features/archive/domain/archive_job.dart';

/// Asks for a zip's password (TASK-B5) and runs [attempt] with it while the
/// dialog stays open: a [WrongPassword] shows an error and asks again, any
/// other error closes the dialog and is rethrown. Returns [attempt]'s
/// result, or null when the user cancels. The password lives only in this
/// dialog's state (one job).
Future<T?> showPasswordDialog<T extends Object>(
  BuildContext context, {
  required String zipName,
  required Future<T> Function(String password) attempt,
}) async {
  final result = await showDialog<_Outcome<T>>(
    context: context,
    barrierDismissible: false,
    builder: (_) => PasswordDialog<T>(zipName: zipName, attempt: attempt),
  );
  switch (result) {
    case null:
      return null;
    case _Done<T>(:final value):
      return value;
    case _Failed<T>(:final error, :final stack):
      Error.throwWithStackTrace(error, stack);
  }
}

sealed class _Outcome<T> {
  const new();
}

final class _Done<T> extends _Outcome<T> {
  const new(this.value);
  final T value;
}

final class _Failed<T> extends _Outcome<T> {
  const new(this.error, this.stack);
  final Object error;
  final StackTrace stack;
}

class PasswordDialog<T extends Object> extends StatefulWidget {
  const new({required this.zipName, required this.attempt, super.key});

  final String zipName;
  final Future<T> Function(String password) attempt;

  @override
  State<PasswordDialog<T>> createState() => _PasswordDialogState<T>();
}

class _PasswordDialogState<T extends Object> extends State<PasswordDialog<T>> {
  final _password = TextEditingController();
  bool _wrong = false;
  bool _busy = false;
  bool _obscure = true;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || _password.text.isEmpty) return;
    setState(() {
      _busy = true;
      _wrong = false;
    });
    final navigator = Navigator.of(context);
    _Outcome<T>? outcome;
    try {
      outcome = _Done(await widget.attempt(_password.text));
    } on WrongPassword {
      outcome = null;
    } on Object catch (e, st) {
      outcome = _Failed(e, st);
    }
    if (!mounted) return;
    if (outcome == null) {
      setState(() {
        _busy = false;
        _wrong = true;
      });
      _password.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _password.text.length,
      );
      return;
    }
    navigator.pop(outcome);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.archivePasswordTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.archivePasswordBody(widget.zipName)),
          TextField(
            controller: _password,
            autofocus: true,
            obscureText: _obscure,
            enabled: !_busy,
            decoration: InputDecoration(
              labelText: l10n.archivePasswordLabel,
              errorText: _wrong ? l10n.archiveWrongPassword : null,
              suffixIcon: IconButton(
                tooltip: _obscure
                    ? l10n.archivePasswordShow
                    : l10n.archivePasswordHide,
                icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            onChanged: (_) {
              if (_wrong) setState(() => _wrong = false);
            },
            onSubmitted: (_) => unawaited(_submit()),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _busy ? null : () => unawaited(_submit()),
          child: Text(l10n.archivePasswordAction),
        ),
      ],
    );
  }
}
