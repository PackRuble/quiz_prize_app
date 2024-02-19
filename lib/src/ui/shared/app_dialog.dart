import 'package:flutter/material.dart';

import 'cardpad.dart';

class AppDialog extends StatelessWidget {
  const AppDialog({
    super.key,
    required this.title,
    this.actions,
    this.child,
    this.message,
  }) : assert(actions == null || message != null);

  final List<Widget>? actions;
  final String title;

  /// use [message] or [child].
  final String? message;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final mqd = MediaQuery.of(context);
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return AlertDialog(
      scrollable: true,
      title: Text(title),
      content: SizedBox(
        width: mqd.size.width * .7,
        child: CardPad(
          margin: EdgeInsets.zero,
          child: child ??
              Center(
                child: Text(
                  message!,
                  style: textTheme.bodyLarge,
                ),
              ),
        ),
      ),
      actions: actions,
    );
  }
}
