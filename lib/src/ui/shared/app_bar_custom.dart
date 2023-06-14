import 'package:flutter/material.dart';

import 'cardpad.dart';

class AppBarCustom extends StatelessWidget implements PreferredSizeWidget {
  const AppBarCustom({
    super.key,
    this.child,
    this.actions = const [],
    this.withBackButton = true,
    this.title,
  });

  final List<Widget> actions;

  /// Custom widget, usually this is [Row].
  final Widget? child;

  final bool withBackButton;

  final String? title;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 16.0);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return CardPad(
      padding: EdgeInsets.zero,
      child: child ??
          Row(
            children: [
              if (withBackButton) const BackButton(),
              const SizedBox(width: 8),
              if (title != null)
                Text('Statistics', style: textTheme.headlineSmall),
              ...actions,
            ],
          ),
    );
  }
}
