import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/form_factor.dart';

/// Keeps the phone in portrait while [child] is the visible, current page
/// (user, 2026-11-04: no swiping in landscape). A hidden tab (TickerMode
/// off) or a page pushed on top (the viewer) lets the phone rotate again.
/// Nothing on desktop.
class PortraitLock extends ConsumerStatefulWidget {
  const new({required this.child, super.key});

  final Widget child;

  /// How many locks hold portrait now (a remote deck can sit on top of the
  /// Swipe tab's): orientations are restored when the last one lets go.
  @visibleForTesting
  static int holders = 0;

  @override
  ConsumerState<PortraitLock> createState() => _PortraitLockState();
}

class _PortraitLockState extends ConsumerState<PortraitLock> {
  bool _holding = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final wanted =
        !ref.read(formFactorProvider).isDesktop &&
        TickerMode.valuesOf(context).enabled &&
        (ModalRoute.of(context)?.isCurrent ?? true);
    _hold(wanted);
  }

  @override
  void dispose() {
    _hold(false);
    super.dispose();
  }

  void _hold(bool wanted) {
    if (wanted == _holding) return;
    _holding = wanted;
    if (wanted) {
      PortraitLock.holders++;
      if (PortraitLock.holders == 1) {
        SystemChrome.setPreferredOrientations(const [
          DeviceOrientation.portraitUp,
        ]).ignore();
      }
    } else {
      PortraitLock.holders--;
      if (PortraitLock.holders == 0) {
        // Empty = whatever the system allows.
        SystemChrome.setPreferredOrientations(const []).ignore();
      }
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
