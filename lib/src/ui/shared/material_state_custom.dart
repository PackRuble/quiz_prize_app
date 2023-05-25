import 'package:flutter/material.dart';

/// More info - [MaterialStateColor].
abstract class MaterialStateColorOrNull extends Color
    implements MaterialStateProperty<Color?> {
  const MaterialStateColorOrNull(super.defaultValue);

  static MaterialStateColorOrNull resolveWith(
          MaterialPropertyResolver<Color?> callback) =>
      _MaterialStateColorOrNull(callback);

  @override
  Color? resolve(Set<MaterialState> states);
}

class _MaterialStateColorOrNull extends MaterialStateColorOrNull {
  _MaterialStateColorOrNull(this._resolve)
      : super(_resolve.call(_defaultStates)?.value ?? 0);

  final MaterialPropertyResolver<Color?> _resolve;

  static const Set<MaterialState> _defaultStates = <MaterialState>{};

  @override
  Color? resolve(Set<MaterialState> states) => _resolve.call(states);
}
