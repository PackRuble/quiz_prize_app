import 'package:flutter/material.dart';

class AppBarCustom extends StatelessWidget implements PreferredSizeWidget {
  const AppBarCustom({super.key, this.children = const <Widget>[]});

  final List<Widget> children;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Row(
        children: children,
      ),
    );
  }
}
