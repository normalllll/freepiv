/// Converts ticker elapsed time into travel, independent of frame frequency.
/// Reset on every explicit start/pause and at segment transitions, so inactive
/// time and layout waits never become a jump on resumption.
class ReaderScrollClock {
  Duration? _lastElapsed;

  void reset() => _lastElapsed = null;

  double advance(Duration elapsed, double pixelsPerSecond) {
    final previous = _lastElapsed;
    _lastElapsed = elapsed;
    if (previous == null || elapsed <= previous) return 0;
    return (elapsed - previous).inMicroseconds / Duration.microsecondsPerSecond * pixelsPerSecond;
  }
}
