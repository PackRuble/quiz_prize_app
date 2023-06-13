import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:weather_animation/weather_animation.dart';

class ResponsiveWindow extends ConsumerWidget {
  const ResponsiveWindow({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.of(context).size;

    const gameSize = Size(864.0, 684.0);

    final child = size.width >= gameSize.width || size.height >= gameSize.height
        ? Stack(
            children: [
              const BackAnimated(),
              Center(
                child: ClipRect(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: gameSize.width,
                      maxHeight: gameSize.height,
                    ),
                    child: this.child,
                  ),
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
    final size = MediaQuery.of(context).size;

    return WrapperScene(
      sizeCanvas: size,
      colors: [
        Colors.orange.shade600,
        Colors.white70,
        Colors.orange.shade100,
        Colors.white60,
        Colors.blue.shade400,
      ],
      children: [
        SnowWidget(
          snowConfig: SnowConfig(
            widgetSnowflake: Icon(
              Icons.cruelty_free,
              color: th.colorScheme.primary,
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
