import 'package:flutter/material.dart' show Size;

final class AppSize {
  AppSize._();

  static const preferredSize = Size(684.0, 864.0);

  static bool isPreferredSize(Size size) =>
      size.width >= preferredSize.width || size.height >= preferredSize.height;
}
