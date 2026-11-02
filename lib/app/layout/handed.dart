import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'handed.g.dart';

/// L4. Which thumb the user swipes with.
///
/// Rule: thumb-side bottom controls use **physical** sides chosen by
/// handedness (these helpers, with `textDirection: TextDirection.ltr`),
/// ignoring text direction. Everything else stays directional. Never wrap
/// widgets in `Directionality` to fake mirroring (that flips text too).
enum Handedness { right, left }

/// keepAlive stream like `themeModeProvider`.
@Riverpod(keepAlive: true)
Stream<Handedness> handedness(Ref ref) => ref
    .watch(settingsRepositoryProvider)
    .watch(AppSettings.leftHanded)
    .map((left) => left ? Handedness.left : Handedness.right);

/// While loading: right-handed (the default layout).
Handedness handednessOf(WidgetRef ref) =>
    ref.watch(handednessProvider).value ?? Handedness.right;

/// The physical side the "secondary" bottom control (Undo) sits on, for a
/// `Row(textDirection: TextDirection.ltr)`. Right-handed → left (the
/// default layout); left-handed → right.
MainAxisAlignment secondarySide(Handedness h) =>
    h == Handedness.right ? MainAxisAlignment.start : MainAxisAlignment.end;

/// [defaultOrder] is the order in the right-handed layout, physical left to
/// right. Left-handed reverses it. Use with `textDirection: TextDirection.ltr`.
List<Widget> mirroredFor(Handedness h, List<Widget> defaultOrder) =>
    h == Handedness.right ? defaultOrder : defaultOrder.reversed.toList();

/// `reverse:` for a horizontal scroll view whose first item belongs at the
/// physical left (right-handed) or physical right (left-handed), whatever
/// the ambient text direction (a horizontal scroll view starts at the
/// ambient start side).
bool reverseHorizontalFor(Handedness h, TextDirection ambient) =>
    (h == Handedness.left) != (ambient == TextDirection.rtl);
