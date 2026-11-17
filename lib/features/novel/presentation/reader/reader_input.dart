import 'package:flutter/services.dart';
import 'package:freepiv/core/services/app_settings.dart';

/// What a key or a tap asks of the reader.
enum ReaderCommand {
  /// The next screen (scroll) or page (paged).
  nextScreen,
  previousScreen,

  /// A few lines down or up; scroll mode only.
  lineDown,
  lineUp,
  nextChapter,
  previousChapter,
  start,
  end,
  contents,

  /// Clears the selection, else closes what is open, else leaves.
  escape,
}

/// The reader's command for a key press, null for keys it leaves alone.
///
/// Presses with Control, Meta or Alt are left to shortcuts such as copy.
ReaderCommand? readerCommandFor(KeyEvent event, {required ReaderPageMode mode}) {
  if (event is! KeyDownEvent && event is! KeyRepeatEvent) return null;
  final keyboard = HardwareKeyboard.instance;
  if (keyboard.isControlPressed || keyboard.isMetaPressed || keyboard.isAltPressed) return null;
  final paged = mode == ReaderPageMode.paged;
  return switch (event.logicalKey) {
    LogicalKeyboardKey.space => keyboard.isShiftPressed ? ReaderCommand.previousScreen : ReaderCommand.nextScreen,
    LogicalKeyboardKey.pageDown || LogicalKeyboardKey.arrowRight => ReaderCommand.nextScreen,
    LogicalKeyboardKey.pageUp || LogicalKeyboardKey.arrowLeft => ReaderCommand.previousScreen,
    LogicalKeyboardKey.arrowDown => paged ? ReaderCommand.nextScreen : ReaderCommand.lineDown,
    LogicalKeyboardKey.arrowUp => paged ? ReaderCommand.previousScreen : ReaderCommand.lineUp,
    LogicalKeyboardKey.bracketRight => ReaderCommand.nextChapter,
    LogicalKeyboardKey.bracketLeft => ReaderCommand.previousChapter,
    LogicalKeyboardKey.home => ReaderCommand.start,
    LogicalKeyboardKey.end => ReaderCommand.end,
    LogicalKeyboardKey.keyT => ReaderCommand.contents,
    LogicalKeyboardKey.escape => ReaderCommand.escape,
    _ => null,
  };
}

/// Where a tap on the text lands, by [ReaderTapZones].
enum ReaderTapAction { back, forward, toggleBars }

/// The action of a tap at [position] in an area of [size].
///
/// [ReaderTapZones.sides]: the left third goes back, the right third forward
/// and the middle third shows or hides the bars. [ReaderTapZones.forward]:
/// the centre cell shows or hides the bars and every other tap goes forward.
ReaderTapAction readerTapActionFor(Offset position, Size size, ReaderTapZones zones) {
  final column = size.width <= 0 ? 1 : (position.dx * 3 / size.width).floor().clamp(0, 2);
  final row = size.height <= 0 ? 1 : (position.dy * 3 / size.height).floor().clamp(0, 2);
  return switch (zones) {
    ReaderTapZones.sides => switch (column) {
      0 => ReaderTapAction.back,
      2 => ReaderTapAction.forward,
      _ => ReaderTapAction.toggleBars,
    },
    ReaderTapZones.forward => column == 1 && row == 1 ? ReaderTapAction.toggleBars : ReaderTapAction.forward,
  };
}
