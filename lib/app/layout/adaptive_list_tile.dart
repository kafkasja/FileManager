import 'package:flutter/material.dart';
import 'package:kfm/app/layout/text_scale.dart';

/// L5: a [ListTile] whose [trailing] (badge, dropdown…) moves under the
/// subtitle at big text sizes ([isBigText]), so it never squeezes the title
/// to nothing or overflows the row. Normal sizes: a plain [ListTile].
class AdaptiveListTile extends StatelessWidget {
  const new({
    required this.title,
    this.leading,
    this.subtitle,
    this.trailing,
    this.selected = false,
    this.onTap,
    this.onLongPress,
    super.key,
  });

  final Widget title;
  final Widget? leading;
  final Widget? subtitle;
  final Widget? trailing;
  final bool selected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final below = trailing != null && isBigText(context);
    return ListTile(
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
      selected: selected,
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
}
