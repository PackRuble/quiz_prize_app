// ignore_for_file: prefer_if_elements_to_conditional_expressions

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:weather_animation/weather_animation.dart';

import '../const/app_size.dart';

class ResponsiveWindow extends ConsumerWidget {
  const ResponsiveWindow({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.sizeOf(context);
    final isPreferredSize = AppSize.isPreferredSize(size);

    final child = isPreferredSize
        ? Stack(
            children: [
              const BackAnimated(),
              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: AppSize.preferredSize.width,
                    maxHeight: AppSize.preferredSize.height,
                  ),
                  child: this.child,
                ),
              ),
            ],
          )
        : this.child;

    return child;
  }
}

class BackAnimated extends ConsumerWidget {
  const BackAnimated({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final th = Theme.of(context);
    final colorScheme = th.colorScheme;
    final isDark = th.brightness == Brightness.dark;
    final size = MediaQuery.sizeOf(context);

    return WrapperScene(
      sizeCanvas: size,
      colors: [
        th.colorScheme.primary,
        isDark ? Colors.grey.shade900 : Colors.grey.shade300,
        th.colorScheme.secondary,
        isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        th.colorScheme.secondary,
      ],
      children: [
        SnowWidget(
          key: ValueKey(size.hashCode),
          snowConfig: SnowConfig(
            widgetSnowflake: Icon(
              Icons.cruelty_free,
              color:
                  isDark ? colorScheme.primaryContainer : colorScheme.primary,
            ),
            areaXStart: 0,
            areaYStart: 0,
            areaXEnd: size.width,
            areaYEnd: size.height,
            count: 25,
          ),
        ),
      ],
    );
  }
}
