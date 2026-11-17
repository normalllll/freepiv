import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:freepiv/core/services/app_settings.dart';
import 'package:freepiv/features/novel/domain/reader_model.dart';

/// Writes a reading position: the character offset and the text's length.
typedef ReaderProgressSink = Future<void> Function(int offset, int totalLength);

/// What a reader view does for the controller.
abstract interface class ReaderViewport {
  /// Shows [offset] at the reading line: the top of the text in scroll mode,
  /// the page holding it in paged mode.
  void showOffset(int offset);

  /// Moves one screen (scroll) or one page or spread (paged) in [direction]
  /// (+1 forward, -1 back); false when already at that end.
  bool turn(int direction);
}

/// The reading position of one text, as a model character offset.
///
/// Views report where the reader is with [reportPosition] and never move on
/// their own; commands move the position and ask the attached view to show
/// it. Every change is saved at most once per save interval, with the latest
/// position: the offset, or the end of the text while the view is at the end.
class ReaderController extends ChangeNotifier {
  ReaderController({
    required this._model,
    required int initialOffset,
    required this._mode,
    required this._save,
    this._saveInterval = const Duration(seconds: 1),
    bool initialAtEnd = false,
  }) {
    // A reader that finished the text opens at its end, whatever length the
    // text had then.
    _atEnd = initialAtEnd;
    _offset = initialAtEnd ? _model.totalLength : _clamp(initialOffset);
    _written = _saved;
  }

  final ReaderModel _model;
  final ReaderProgressSink _save;
  final Duration _saveInterval;

  late int _offset;
  late int _written;
  bool _atEnd = false;

  /// What a save writes: the end of the text while at the end, so a reopen
  /// shows the end again; otherwise the offset.
  int get _saved => _atEnd ? _model.totalLength : _offset;
  ReaderPageMode _mode;
  ReaderViewport? _viewport;
  Timer? _saveTimer;

  ReaderModel get model => _model;

  int get offset => _offset;

  ReaderChapter get chapter => _model.chapterAt(_offset);

  /// 1.0 once the view reported the end, else the share of characters before
  /// the offset.
  double get progress {
    if (_atEnd) return 1.0;
    final total = _model.totalLength;
    return total == 0 ? 0 : _offset / total;
  }

  bool get atEnd => _atEnd;

  ReaderPageMode get mode => _mode;

  set mode(ReaderPageMode value) {
    if (value == _mode) return;
    _mode = value;
    notifyListeners();
    _viewport?.showOffset(_offset);
  }

  void attach(ReaderViewport viewport) {
    _viewport = viewport;
    viewport.showOffset(_offset);
  }

  void detach(ReaderViewport viewport) {
    if (identical(_viewport, viewport)) _viewport = null;
  }

  /// Where the view now is; never calls back into the view.
  void reportPosition(int offset, {bool atEnd = false}) {
    final next = _clamp(offset);
    final moved = next != _offset;
    if (!moved && atEnd == _atEnd) return;
    _offset = next;
    _atEnd = atEnd;
    notifyListeners();
    _scheduleSave();
  }

  void goToOffset(int offset) => _goTo(_clamp(offset));

  void goToFraction(double fraction) => _goTo((fraction.clamp(0.0, 1.0) * _model.totalLength).round());

  void goToChapter(int index) {
    final chapters = _model.chapters;
    _goTo(chapters[index.clamp(0, chapters.length - 1)].startOffset);
  }

  /// False on the last chapter, where nothing moves.
  bool nextChapter() {
    final index = chapter.index;
    if (index + 1 >= _model.chapters.length) return false;
    _goTo(_model.chapters[index + 1].startOffset);
    return true;
  }

  /// To the previous chapter's start; on the first chapter to the start of
  /// the text, false when already there.
  bool previousChapter() {
    final index = chapter.index;
    if (index > 0) {
      _goTo(_model.chapters[index - 1].startOffset);
      return true;
    }
    if (_offset == 0) return false;
    _goTo(0);
    return true;
  }

  void goToPixivPage(int page) => _goTo(_model.offsetOfPage(page));

  void goToStart() => _goTo(0);

  void goToEnd() => _goTo(_model.totalLength, atEnd: true);

  bool nextScreen() => _viewport?.turn(1) ?? false;

  bool previousScreen() => _viewport?.turn(-1) ?? false;

  /// Writes the offset now when it changed since the last write; cancels a
  /// pending timed write.
  Future<void> saveNow() {
    _saveTimer?.cancel();
    _saveTimer = null;
    return _write();
  }

  @override
  void dispose() {
    unawaited(saveNow());
    super.dispose();
  }

  int _clamp(int offset) => offset.clamp(0, _model.totalLength);

  /// A command that lands on the current offset only re-shows it (the view
  /// may have drifted inside the line), except [goToEnd] marking the end.
  void _goTo(int offset, {bool atEnd = false}) {
    final changed = offset != _offset || (atEnd && !_atEnd);
    if (changed) {
      _offset = offset;
      _atEnd = atEnd;
      notifyListeners();
    }
    _viewport?.showOffset(offset);
    if (changed) _scheduleSave();
  }

  void _scheduleSave() {
    _saveTimer ??= Timer(_saveInterval, () {
      _saveTimer = null;
      unawaited(_write());
    });
  }

  Future<void> _write() async {
    final offset = _saved;
    if (offset == _written) return;
    final previous = _written;
    _written = offset;
    try {
      await _save(offset, _model.totalLength);
    } catch (_) {
      // A failed write is retried by the next change or saveNow.
      if (_written == offset) _written = previous;
    }
  }
}
