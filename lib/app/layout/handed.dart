import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'handed.g.dart';

/// L4. Which thumb the user swipes with.
///
/// Rule (TASK-E2 §7): Undo, the main bottom buttons, the selection bar's
/// actions and FABs sit on the **thumb side** (right-handed → right,
/// left-handed → left). Physical sides, chosen by handedness (these
/// helpers, with `textDirection: TextDirection.ltr`), ignoring text
/// direction. Everything else stays directional. Never wrap widgets in
/// `Directionality` to fake mirroring (that flips text too). Desktop has no
/// thumb: these are phone-only.
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

/// The physical side thumb controls (Undo) sit on, for a
/// `Row(textDirection: TextDirection.ltr)`: right-handed → right,
/// left-handed → left.
MainAxisAlignment thumbSide(Handedness h) =>
    h == Handedness.right ? MainAxisAlignment.end : MainAxisAlignment.start;

/// [defaultOrder] is the order in the right-handed layout, physical left to
/// right (its last items sit at the thumb). Left-handed reverses it. Use
/// with `textDirection: TextDirection.ltr`.
List<Widget> mirroredFor(Handedness h, List<Widget> defaultOrder) =>
    h == Handedness.right ? defaultOrder : defaultOrder.reversed.toList();

/// [items] from the thumb outwards: the first sits at the thumb side
/// (physical right for right-handed). Use with
/// `textDirection: TextDirection.ltr`.
List<Widget> thumbFirst(Handedness h, List<Widget> items) =>
    h == Handedness.right ? items.reversed.toList() : items;

/// `reverse:` for a horizontal scroll view whose first item belongs at the
/// thumb side (physical right for right-handed, left for left-handed),
/// whatever the ambient text direction (a horizontal scroll view starts at
/// the ambient start side).
bool reverseHorizontalFor(Handedness h, TextDirection ambient) =>
    (h == Handedness.right) != (ambient == TextDirection.rtl);

/// A floating action button on the thumb side (every phone FAB uses it; a
/// rule test checks).
FloatingActionButtonLocation thumbFabLocation(
  Handedness h,
  TextDirection ambient,
) => (h == Handedness.right) == (ambient == TextDirection.ltr)
    ? FloatingActionButtonLocation.endFloat
    : FloatingActionButtonLocation.startFloat;
