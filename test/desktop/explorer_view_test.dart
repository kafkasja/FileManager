import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/desktop/widgets/explorer_selection.dart';
import 'package:kfm/desktop/widgets/explorer_view.dart';

/// Counts its own `initState` calls (a new element = a reloaded thumbnail).
class _Probe extends StatefulWidget {
  const new(this.label);

  final String label;
  static int created = 0;

  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> {
  @override
  void initState() {
    super.initState();
    _Probe.created++;
  }

  @override
  Widget build(BuildContext context) => Text(widget.label);
}

void main() {
  Widget view(List<String> items, ExplorerLayout layout) => MaterialApp(
    home: Scaffold(
      body: ExplorerView<String>(
        items: items,
        idOf: (s) => s,
        layout: layout,
        selection: ExplorerSelection.empty,
        onSelectionChanged: (_) {},
        tileBuilder: (context, s, {required extent}) => _Probe(s),
        columns: [
          ExplorerColumn<String>(
            id: 'name',
            label: 'Name',
            expand: true,
            cell: (context, s) => _Probe(s),
          ),
        ],
      ),
    ),
  );

  for (final layout in [ExplorerLayout.grid, ExplorerLayout.details]) {
    testWidgets('${layout.name}: removing the first item keeps the other '
        "items' elements (Sort: no thumbnail reload per action)", (
      tester,
    ) async {
      final items = [for (var i = 0; i < 40; i++) 'f$i'];
      await tester.pumpWidget(view(items, layout));
      final shown = _Probe.created;
      expect(shown, greaterThan(5));
      _Probe.created = 0;
      await tester.pumpWidget(view(items.sublist(1), layout));
      // At most the item that scrolled into view at the end is new.
      expect(
        _Probe.created,
        lessThanOrEqualTo(layout == ExplorerLayout.grid ? 8 : 1),
      );
      expect(find.text('f0'), findsNothing);
      expect(find.text('f1'), findsOneWidget);
      _Probe.created = 0;
    });
  }

  testWidgets('an autofocus view takes the focus again when its section is '
      'shown again (keys work after a sidebar switch)', (tester) async {
    Widget section(String id, {required bool active}) => Offstage(
      offstage: !active,
      child: TickerMode(
        enabled: active,
        child: ExplorerView<String>(
          key: ValueKey(id),
          autofocus: true,
          items: ['$id-a', '$id-b'],
          idOf: (s) => s,
          layout: ExplorerLayout.details,
          selection: ExplorerSelection.empty,
          onSelectionChanged: (_) {},
          tileBuilder: (context, s, {required extent}) => Text(s),
          columns: [
            ExplorerColumn<String>(
              id: 'name',
              label: 'Name',
              expand: true,
              cell: (context, s) => Text(s),
            ),
          ],
        ),
      ),
    );
    Widget shell(String current) => MaterialApp(
      home: Scaffold(
        body: Stack(
          children: [
            section('sort', active: current == 'sort'),
            section('browse', active: current == 'browse'),
          ],
        ),
      ),
    );
    bool focusedIn(String id) {
      final primary = FocusManager.instance.primaryFocus?.context;
      return primary != null &&
          primary.findAncestorWidgetOfExactType<ExplorerView<String>>()?.key ==
              ValueKey(id);
    }

    await tester.pumpWidget(shell('sort'));
    await tester.pump();
    await tester.pumpWidget(shell('browse'));
    await tester.pump();
    await tester.pumpWidget(shell('sort'));
    await tester.pump();
    expect(focusedIn('sort'), isTrue);
    await tester.pumpWidget(shell('browse'));
    await tester.pump();
    expect(focusedIn('browse'), isTrue);
  });
}
