/// An [Iterator] that allows moving backwards as well as forwards.
abstract interface class BidirectionalIterator<E> implements Iterator<E> {
  /// Move back to the previous element.
  ///
  /// Returns true and updates [current] if successful. Returns false
  /// and updates [current] to an implementation defined state if there is no
  /// previous element
  bool movePrevious();
}

/// An [Iterator] that iterates a list-like [Iterable]. Supports backward iteration.
///
/// All iterations is done in terms of [Iterable.length] and
/// [Iterable.elementAt]. These operations are fast for list-like
/// iterables.
class ListBiIterator<E> implements BidirectionalIterator<E> {
  final Iterable<E> _iterable;
  final int _length;
  int _index;
  E? _current;

  @override
  E get current => _current as E;

  ListBiIterator(Iterable<E> iterable)
      : _iterable = iterable,
        _length = iterable.length,
        _index = 0;

  @override
  bool moveNext() {
    final length = _iterable.length;
    if (_length != length) throw ConcurrentModificationError(_iterable);

    if (_index >= length) {
      _current = null;
      return false;
    } else {
      _current = _iterable.elementAt(_index);
      _index++;
      return true;
    }
  }

  @override
  bool movePrevious() {
    final length = _iterable.length;
    if (_length != length) throw ConcurrentModificationError(_iterable);

    if (_index == 0) {
      _current = null;
      return false;
    } else {
      _index--;
      _current = _iterable.elementAt(_index);
      return true;
    }
  }
}
