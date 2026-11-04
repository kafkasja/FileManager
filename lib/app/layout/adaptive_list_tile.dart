import 'package:flutter/material.dart';
import 'package:kfm/app/layout/text_scale.dart';

/// L5: a [ListTile] whose [trailing] (badge, dropdown…) moves under the
/// subtitle at big text sizes ([isBigText]) or in a narrow row, so it never
/// squeezes the title to nothing or overflows the row. Otherwise a plain
/// [ListTile].
class AdaptiveListTile extends StatelessWidget {
  const new({
    required this.title,
    this.leading,
    this.subtitle,
    this.trailing,
    this.selected = false,
    this.onTap,
    this.onLongPress,
    this.contentPadding,
    this.isThreeLine,
    super.key,
  });

  final Widget title;
  final Widget? leading;
  final Widget? subtitle;
  final Widget? trailing;
  final bool selected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsetsGeometry? contentPadding;

  /// Passed on while the trailing widget stays at the end.
  final bool? isThreeLine;

  /// Narrower than this (a desktop settings pane in an 800 px window), the
  /// trailing widget also moves under the text: ListTile asserts when it
  /// takes the whole row.
  static const narrowWidth = 360.0;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) => _tile(
      context,
      below:
          trailing != null &&
          (isBigText(context) || box.maxWidth < narrowWidth),
    ),
  );

  Widget _tile(BuildContext context, {required bool below}) {
    return ListTile(
      contentPadding: contentPadding,
      leading: leading,
      title: title,
      subtitle: below
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ?subtitle,
                // Shrinks (never overflows) when still wider than the row.
                FittedBox(fit: BoxFit.scaleDown, child: trailing),
              ],
            )
          : subtitle,
      trailing: below ? null : trailing,
      isThreeLine: below ? null : isThreeLine,
      selected: selected,
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
}
