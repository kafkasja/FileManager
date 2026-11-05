import 'package:flutter/material.dart';
import 'package:kfm/app/theme/app_tokens.dart';

/// E4 (A11): an empty list's icon, one line of text and an optional action,
/// centered; scrolls when big text doesn't fit (like Swipe's message).
class EmptyState extends StatelessWidget {
  const new({required this.icon, required this.text, this.action, super.key});

  final IconData icon;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final spacing = context.tokens.spacing;
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsetsDirectional.all(spacing * 3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: Theme.of(context).colorScheme.outline),
            SizedBox(height: spacing * 2),
            Text(text, textAlign: TextAlign.center),
            if (action case final action?) ...[
              SizedBox(height: spacing),
              action,
            ],
          ],
        ),
      ),
    );
  }
}
