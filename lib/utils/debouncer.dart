import "dart:async";

class Debouncer<T> {
  final Duration duration;
  final void Function(T? prev, T next) listener;

  Debouncer(this.duration, this.listener);

  T? prev;
  late T _next;

  Future<void> debounce(T value) async {
    _next = value;

    await Future<void>.delayed(duration);

    if (_next == value) {
      listener(prev, _next);
      prev = _next;
    }
  }
}
