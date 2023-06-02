import 'dart:ui';

extension ColorHex on Color {
  /// String is in the format "aabbcc" or "ffaabbcc" with an optional leading "#".
  static Color fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  String get hexCode {
    return value.toRadixString(16).toUpperCase().padLeft(8, '0');
  }

  String get hex {
    return '#${value.toRadixString(16).toUpperCase().padLeft(8, '0').substring(2)}';
  }

  String get hexMaterial {
    return '0x${value.toRadixString(16).padLeft(8, '0')}';
  }
}
