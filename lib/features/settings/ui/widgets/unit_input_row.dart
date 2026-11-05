import 'package:flutter/material.dart';
import 'package:kfm/app/adaptive_sheet.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/core/utils/format.dart';
import 'package:kfm/core/utils/human_units.dart';
import 'package:kfm/features/settings/ui/widgets/settings_tiles.dart';
import 'package:kfm/l10n/generated/app_localizations.dart';

/// A setting that takes any amount in human units (TASK-E2 §4): the row
/// shows [subtitle] (with the current value), a tap opens a sheet (dialog
/// on desktop) with [presets] as chips plus a number field and a unit.
class UnitInputRow extends StatelessWidget {
  const new({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.min,
    required this.max,
    required this.units,
    required this.presets,
    required this.format,
    required this.onSaved,
    this.icon,
    super.key,
  });

  /// One MB … one TB.
  const new size({
    required String title,
    required String subtitle,
    required int value,
    required List<int> presets,
    required String Function(int) format,
    required ValueChanged<int> onSaved,
    IconData? icon,
    Key? key,
  }) : this(
         title: title,
         subtitle: subtitle,
         value: value,
         min: 1024 * 1024,
         max: 1024 * 1024 * 1024 * 1024,
         units: InputUnit.sizeUnits,
         presets: presets,
         format: format,
         onSaved: onSaved,
         icon: icon,
         key: key,
       );

  /// One second … 24 hours.
  const new duration({
    required String title,
    required String subtitle,
    required int value,
    required List<int> presets,
    required String Function(int) format,
    required ValueChanged<int> onSaved,
    IconData? icon,
    Key? key,
  }) : this(
         title: title,
         subtitle: subtitle,
         value: value,
         min: 1,
         max: 24 * 3600,
         units: InputUnit.durationUnits,
         presets: presets,
         format: format,
         onSaved: onSaved,
         icon: icon,
         key: key,
       );

  final String title;
  final String subtitle;
  final IconData? icon;
  final int value;

  /// Allowed range in base units (bytes, seconds), inclusive.
  final int min;
  final int max;
  final List<InputUnit> units;
  final List<int> presets;

  /// Base units → "250 MB", "2 min".
  final String Function(int value) format;
  final ValueChanged<int> onSaved;

  @override
  Widget build(BuildContext context) => SettingsTile(
    icon: icon,
    title: title,
    subtitle: subtitle,
    trailing: Text(
      format(value),
      key: const ValueKey('unit-input-value'),
      style: Theme.of(context).textTheme.labelLarge,
    ),
    onTap: () async {
      final picked = await showAdaptiveSheet<int>(
        context: context,
        isScrollControlled: true,
        builder: (_) => UnitInputSheet(
          title: title,
          value: value,
          min: min,
          max: max,
          units: units,
          presets: presets,
          format: format,
        ),
      );
      if (picked != null && picked != value) onSaved(picked);
    },
  );
}

/// The sheet's content. Pops the new value in base units, or null.
class UnitInputSheet extends StatefulWidget {
  const new({
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    required this.units,
    required this.presets,
    required this.format,
    super.key,
  });

  final String title;
  final int value;
  final int min;
  final int max;
  final List<InputUnit> units;
  final List<int> presets;
  final String Function(int value) format;

  @override
  State<UnitInputSheet> createState() => _UnitInputSheetState();
}

class _UnitInputSheetState extends State<UnitInputSheet> {
  late InputUnit _unit = unitFor(widget.value, widget.units);
  late final TextEditingController _text = TextEditingController(
    text: amountText(widget.value, _unit),
  );

  int? get _parsed => parseAmount(_text.text, _unit);

  bool _valid(int? v) => v != null && v >= widget.min && v <= widget.max;

  void _setValue(int v) => setState(() {
    _unit = unitFor(v, widget.units);
    _text.text = amountText(v, _unit);
  });

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final parsed = _parsed;
    final valid = _valid(parsed);
    final insets = MediaQuery.viewInsetsOf(context);
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(24, 8, 24, 16 + insets.bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final p in widget.presets)
                  ChoiceChip(
                    key: ValueKey('unit-preset-$p'),
                    label: Text(widget.format(p)),
                    selected: parsed == p,
                    onSelected: (_) => _setValue(p),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    key: const ValueKey('unit-input-field'),
                    controller: _text,
                    autofocus: true,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) {
                      if (valid) Navigator.pop(context, parsed);
                    },
                    decoration: InputDecoration(
                      labelText: l10n.unitInputAmount,
                      errorText: valid
                          ? null
                          : l10n.unitInputRange(
                              widget.format(widget.min),
                              widget.format(widget.max),
                            ),
                      errorMaxLines: 2,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<InputUnit>(
                  key: const ValueKey('unit-input-unit'),
                  value: _unit,
                  onChanged: (u) {
                    if (u != null) setState(() => _unit = u);
                  },
                  items: [
                    for (final u in widget.units)
                      DropdownMenuItem(value: u, child: Text(u.label(l10n))),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.cancel),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  key: const ValueKey('unit-input-save'),
                  onPressed: valid
                      ? () => Navigator.pop(context, parsed)
                      : null,
                  child: Text(l10n.unitInputSave),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// "250 MB" for the big-file rows (whole numbers when they are).
String formatSizeSetting(BuildContext context, int bytes) =>
    formatBytes(bytes, locale: Localizations.localeOf(context).toLanguageTag());

/// "2 min" for duration rows.
String formatDurationSetting(AppLocalizations l10n, int seconds) =>
    formatShortDuration(l10n, seconds);
