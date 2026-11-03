import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/form_factor.dart';

/// A bottom sheet on the phone, a dialog on the desktop (TASK-PL3: no
/// bottom sheets on desktop). Same content either way; content that
/// scrolls uses [AdaptiveScrollSheet] instead of a
/// `DraggableScrollableSheet`.
Future<T?> showAdaptiveSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = false,
  bool showDragHandle = true,
  double maxDialogWidth = 520,
}) {
  final desktop = ProviderScope.containerOf(
    context,
    listen: false,
  ).read(formFactorProvider).isDesktop;
  if (!desktop) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      showDragHandle: showDragHandle,
      builder: builder,
    );
  }
  return showDialog<T>(
    context: context,
    builder: (context) => DesktopSheetDialog(
      maxWidth: maxDialogWidth,
      child: Builder(builder: builder),
    ),
  );
}

/// The dialog frame [showAdaptiveSheet] uses on the desktop: at most
/// [maxWidth] wide and 80 % of the window high, a close button.
class DesktopSheetDialog extends StatelessWidget {
  const new({required this.child, this.maxWidth = 520, super.key});

  final Widget child;
  final double maxWidth;

  /// True inside a [DesktopSheetDialog].
  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_DesktopSheetScope>() != null;

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * 0.8;
    return Dialog(
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: height),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.only(top: 16, bottom: 8),
              child: _DesktopSheetScope(child: child),
            ),
            PositionedDirectional(
              top: 4,
              end: 4,
              child: IconButton(
                key: const ValueKey('desktop-sheet-close'),
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                icon: const Icon(Icons.close, size: 18),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DesktopSheetScope extends InheritedWidget {
  const new({required super.child});

  @override
  bool updateShouldNotify(_DesktopSheetScope oldWidget) => false;
}

/// Scrolling sheet content: a `DraggableScrollableSheet` on the phone; in
/// a [DesktopSheetDialog] the [builder] gets its own controller and
/// `shrinkWrap: true`, so the dialog is only as tall as its content.
class AdaptiveScrollSheet extends StatefulWidget {
  const new({
    required this.builder,
    this.initialChildSize = 0.5,
    this.maxChildSize = 0.9,
    super.key,
  });

  final Widget Function(
    BuildContext context,
    ScrollController controller, {
    required bool shrinkWrap,
  })
  builder;
  final double initialChildSize;
  final double maxChildSize;

  @override
  State<AdaptiveScrollSheet> createState() => _AdaptiveScrollSheetState();
}

class _AdaptiveScrollSheetState extends State<AdaptiveScrollSheet> {
  ScrollController? _own;

  @override
  void dispose() {
    _own?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (DesktopSheetDialog.of(context)) {
      final controller = _own ??= ScrollController();
      return widget.builder(context, controller, shrinkWrap: true);
    }
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: widget.initialChildSize,
      maxChildSize: widget.maxChildSize,
      builder: (context, scroll) =>
          widget.builder(context, scroll, shrinkWrap: false),
    );
  }
}
