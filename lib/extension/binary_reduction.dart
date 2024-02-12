
/// Result: list of 1 <= item <= ([up] / 2).ceil())
///
/// More info: https://gist.github.com/PackRuble/3857005d72103dbac16a5975e934070f
///
/// Examples:
/// up: [list of reduction numbers]
///  2: [ 1]
///  4: [ 2,  1]
///  8: [ 4,  2, 1]
/// 16: [ 8,  4, 2, 1]
/// 32: [16,  8, 4, 2, 1]
/// 64: [32, 16, 8, 4, 2, 1]
///
List<int> getReductionsSequence(int up) {
  final reductions = <int>[];
  int val = up;
  do {
    val = (val / 2).ceil();
    reductions.add(val);
  } while (val != 1);
  return reductions;
}
